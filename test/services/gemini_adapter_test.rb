require "test_helper"

class GeminiAdapterTest < ActiveSupport::TestCase
  Response = Struct.new(:body, :code)

  test "treats an HTTP timeout as a retryable provider failure" do
    response = Response.new('{"error":{"message":"Gemini timed out."}}', "408")
    adapter = TimeoutGeminiAdapter.new(response)

    error = assert_raises(GeminiAdapter::RetryableError) do
      adapter.analyze(source_url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ", output_language: "pl")
    end

    assert_equal "Gemini timed out.", error.message
  end

  class TimeoutGeminiAdapter < GeminiAdapter
    def initialize(response)
      @response = response
    end

    private

    def post_interaction(source_url:, output_language:)
      @response
    end
  end
end
