ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module WorkspaceAccessTestHelper
  def unlock_workspace(password: "a private test password")
    with_owner_password(password) do
      post "/access", params: { password: }
    end
  end

  def with_owner_password(password)
    previous_password = ENV.fetch("OWNER_PASSWORD", nil)
    ENV["OWNER_PASSWORD"] = password
    yield
  ensure
    ENV["OWNER_PASSWORD"] = previous_password
  end
end

module BriefTestHelper
  def create_completed_brief(source_title:, source_channel:, source_url: nil, output_language: "pl", publicly_visible: false, created_at: nil)
    source_url ||= "https://www.youtube.com/watch?v=#{source_title.parameterize}"
    analysis_request = AnalysisRequest.create!(source_url:)
    analysis_request.update!(lifecycle_state: "completed")

    attributes = {
      analysis_request:,
      source_url:,
      source_title:,
      source_channel:,
      published_on: Date.new(2026, 8, 1),
      duration_seconds: 600,
      output_language:,
      content_markdown: "# #{source_title}",
      structured_content: { "sections" => [ { "heading" => "Details", "body" => "Source details." } ] },
      key_conclusions: [ "One.", "Two.", "Three.", "Four.", "Five." ],
      publicly_visible:
    }
    attributes.merge!(created_at:, updated_at: created_at) if created_at

    Brief.create!(attributes)
  end
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    setup do
      AccessController::ACCESS_RATE_LIMIT_STORE.clear
    end

    # Add more helper methods to be used by all tests here...
  end
end

class ActionDispatch::IntegrationTest
  include WorkspaceAccessTestHelper
  include BriefTestHelper
end
