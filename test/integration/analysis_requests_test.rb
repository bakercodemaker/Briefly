require "test_helper"

class AnalysisRequestsTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  test "an owner submits a public YouTube URL and sees its queued request" do
    unlock_workspace

    assert_difference("AnalysisRequest.count", 1) do
      post "/analysis_requests", params: { analysis_request: { source_url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ" } }
    end

    request = AnalysisRequest.last

    assert_redirected_to "/workspace"
    assert_equal "https://www.youtube.com/watch?v=dQw4w9WgXcQ", request.source_url
    assert_equal "queued", request.lifecycle_state

    follow_redirect!

    assert_select "p", "Analysis request queued."
    assert_select "li", /queued/i
  end

  test "an anonymous visitor cannot submit an analysis request" do
    assert_no_difference("AnalysisRequest.count") do
      post "/analysis_requests", params: { analysis_request: { source_url: "https://youtu.be/dQw4w9WgXcQ" } }
    end

    assert_redirected_to "/access"
  end

  test "an anonymous visitor cannot retry a recoverably failed analysis request" do
    analysis_request = AnalysisRequest.create!(source_url: "https://youtu.be/dQw4w9WgXcQ")
    analysis_request.update!(
      lifecycle_state: "failed",
      recoverable_failure: true,
      automatic_retry_count: 1,
      failure_message: "Gemini quota is temporarily exhausted."
    )

    assert_no_enqueued_jobs do
      post "/analysis_requests/#{analysis_request.id}/retry"
    end

    assert_redirected_to "/access"
    assert_equal "failed", analysis_request.reload.lifecycle_state
    assert analysis_request.recoverable_failure?
  end

  test "an owner receives validation feedback for malformed and unsupported source URLs" do
    unlock_workspace

    [ "not a url", "https://vimeo.com/123456", "https://www.youtube.com/watch?v=" ].each do |source_url|
      assert_no_difference("AnalysisRequest.count") do
        post "/analysis_requests", params: { analysis_request: { source_url: source_url } }
      end

      assert_response :unprocessable_entity
      assert_select "p", "Enter a public YouTube video URL."
    end
  end

  test "an owner cannot queue a second active analysis request" do
    unlock_workspace
    AnalysisRequest.create!(source_url: "https://youtu.be/active")

    assert_no_difference("AnalysisRequest.count") do
      post "/analysis_requests", params: { analysis_request: { source_url: "https://youtu.be/oneTooMany" } }
    end

    assert_response :unprocessable_entity
    assert_select "p", "Wait for an active analysis request to finish before queueing another."
  end

  test "an owner archives a completed request and its Brief from active history" do
    unlock_workspace
    analysis_request = AnalysisRequest.create!(source_url: "https://youtu.be/dQw4w9WgXcQ")
    brief = create_brief_for(analysis_request, source_title: "Archive me")
    analysis_request.update!(lifecycle_state: "completed")

    patch archive_analysis_request_path(analysis_request)

    assert_redirected_to workspace_path
    assert analysis_request.reload.archived?
    assert_equal brief, analysis_request.brief

    follow_redirect!
    assert_select "a", text: "Archive me", count: 0
    assert_select "a", "Archived Briefs"
  end

  test "the workspace keeps request history compact, expands to ten, and paginates older requests" do
    unlock_workspace
    11.times do |index|
      AnalysisRequest.create!(source_url: "https://youtu.be/request#{index}").tap do |analysis_request|
        analysis_request.update_columns(lifecycle_state: "completed", active_slot: nil, created_at: index.minutes.ago)
      end
    end

    get workspace_path

    assert_select "h2", "Analysis Requests"
    assert_select "section ul > li", 3
    assert_select "a", "Show 7 more"

    get workspace_path(show_all_requests: 1)

    assert_select "section ul > li", 10
    assert_select "nav[aria-label='Analysis Request pagination']", /Page 1 of 2/
    assert_select "a", "Older"

    get workspace_path(show_all_requests: 1, requests_page: 2)

    assert_select "section ul > li", 1
    assert_select "nav[aria-label='Analysis Request pagination']", /Page 2 of 2/
  end

  test "a completed request displays its returned video title instead of its YouTube URL" do
    unlock_workspace
    analysis_request = AnalysisRequest.create!(source_url: "https://youtu.be/dQw4w9WgXcQ")
    create_brief_for(analysis_request, source_title: "Returned Gemini title")
    analysis_request.update!(lifecycle_state: "completed")

    get workspace_path

    assert_select "a[href=?]", analysis_request.source_url, "Returned Gemini title"
  end

  test "archiving queued work cancels it before Gemini can claim it" do
    unlock_workspace
    analysis_request = AnalysisRequest.create!(source_url: "https://youtu.be/dQw4w9WgXcQ")

    patch archive_analysis_request_path(analysis_request)

    assert_equal "cancelled", analysis_request.reload.lifecycle_state
    assert analysis_request.archived?
    assert_no_difference("Brief.count") do
      GenerateBriefJob.perform_now(analysis_request.id)
    end
  end

  test "an owner can browse archived Briefs outside the active library" do
    unlock_workspace
    analysis_request = AnalysisRequest.create!(source_url: "https://youtu.be/dQw4w9WgXcQ")
    create_brief_for(analysis_request, source_title: "Archived title")
    analysis_request.update!(lifecycle_state: "completed")
    analysis_request.archive!

    get archived_briefs_path

    assert_response :success
    assert_select "h1", "Archived Briefs"
    assert_select "a[href=?]", brief_path(analysis_request.brief) do
      assert_select "p", "Archived title"
    end
  end

  test "the Personal Brief Library excludes public Demo Briefs" do
    unlock_workspace
    create_completed_brief(
      source_title: "Personal Brief",
      source_channel: "Personal Research",
      publicly_visible: false
    )
    create_completed_brief(
      source_title: "Demo Brief",
      source_channel: "Demo Research",
      publicly_visible: true
    )

    get workspace_path

    assert_select "p", "Personal Brief"
    assert_select "p", { text: "Demo Brief", count: 0 }
  end

  private

  def create_brief_for(analysis_request, source_title:)
    Brief.create!(
      analysis_request:,
      source_url: analysis_request.source_url,
      source_title:,
      source_channel: "Channel",
      published_on: Date.new(2026, 8, 1),
      duration_seconds: 60,
      output_language: "pl",
      content_markdown: "# Brief",
      structured_content: { "sections" => [ { "heading" => "Heading", "body" => "Body" } ] },
      key_conclusions: [ "One", "Two", "Three", "Four", "Five" ]
    )
  end
end
