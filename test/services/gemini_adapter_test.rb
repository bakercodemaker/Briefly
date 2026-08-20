require "test_helper"

class GeminiAdapterTest < ActiveSupport::TestCase
  Response = Struct.new(:body, :code)

  class SuccessfulResponse < Net::HTTPOK
    def initialize(body)
      @body = body
    end

    attr_reader :body
  end

  test "asks Gemini to retain source attribution and uncertainty" do
    adapter = GeminiAdapter.new
    response = successful_response
    request = nil

    with_gemini_api_key do
      request = capture_http_request(response) do
        adapter.analyze(source_url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ", output_language: "pl")
      end
    end

    prompt = JSON.parse(request.body).fetch("input").first.fetch("text")

    assert_includes prompt, "attribution"
    assert_includes prompt, "uncertainty"
  end

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

  private

  def successful_response
    generated_brief = {
      source_title: "Source title",
      source_channel: "Source channel",
      published_on: "2026-08-20",
      duration_seconds: 60,
      content_markdown: "# Brief",
      structured_content: { sections: [ { heading: "Details", body: "Source details." } ] },
      key_conclusions: [ "One.", "Two.", "Three.", "Four.", "Five." ]
    }
    SuccessfulResponse.new({ output_text: generated_brief.to_json }.to_json)
  end

  def with_gemini_api_key
    previous_key = ENV.fetch("GEMINI_API_KEY", nil)
    ENV["GEMINI_API_KEY"] = "test-key"
    yield
  ensure
    ENV["GEMINI_API_KEY"] = previous_key
  end

  def capture_http_request(response)
    http_singleton_class = Net::HTTP.singleton_class
    original_start = Net::HTTP.method(:start)
    request = nil
    http_singleton_class.define_method(:start) do |_host, _port, **_options, &block|
      client = Object.new
      client.define_singleton_method(:request) { |value| request = value; response }
      block.call(client)
    end
    yield
    request
  ensure
    http_singleton_class.define_method(:start, original_start)
  end
end
