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
      automatic_retry_count: 2,
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
end
