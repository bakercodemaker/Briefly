require "test_helper"

class BriefTest < ActiveSupport::TestCase
  test "requires five to ten key conclusions" do
    analysis_request = AnalysisRequest.create!(source_url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")
    brief = Brief.new(
      analysis_request:,
      source_url: analysis_request.source_url,
      source_title: "A source",
      source_channel: "A channel",
      published_on: Date.new(2026, 8, 1),
      duration_seconds: 60,
      output_language: "pl",
      content_markdown: "# A Brief",
      structured_content: { "sections" => [ { "heading" => "A section", "body" => "A source-faithful explanation." } ] },
      key_conclusions: [ "One.", "Two.", "Three.", "Four." ]
    )

    assert_not brief.valid?
    assert_includes brief.errors[:key_conclusions], "is too short (minimum is 5 characters)"
  end
end
