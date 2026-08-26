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

  test "uses the Interactions API array response format" do
    adapter = GeminiAdapter.new
    request = nil

    with_gemini_api_key do
      request = capture_http_request(successful_response) do
        adapter.analyze(source_url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ", output_language: "pl")
      end
    end

    response_format = JSON.parse(request.body).fetch("response_format")
    assert_kind_of Array, response_format
    assert_equal "application/json", response_format.first.fetch("mime_type")
  end

  test "reads generated JSON from the final model output step" do
    adapter = GeminiAdapter.new
    response = successful_steps_response

    brief = nil
    with_gemini_api_key do
      capture_http_request(response) do
        brief = adapter.analyze(source_url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ", output_language: "pl")
      end
    end

    assert_equal "Source title", brief.source_title
  end

  test "treats an HTTP timeout as a retryable provider failure" do
    response = Response.new('{"error":{"message":"Gemini timed out."}}', "408")
    adapter = TimeoutGeminiAdapter.new(response)

    error = assert_raises(GeminiAdapter::RetryableError) do
      adapter.analyze(source_url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ", output_language: "pl")
    end

    assert_equal "Gemini timed out.", error.message
  end

  test "preserves Gemini's quota retry delay" do
    response = Response.new(
      {
        error: {
          message: "Quota exceeded.",
          details: [
            {
              "@type" => "type.googleapis.com/google.rpc.RetryInfo",
              retryDelay: "47.160335681s"
            }
          ]
        }
      }.to_json,
      "429"
    )
    adapter = TimeoutGeminiAdapter.new(response)

    error = assert_raises(GeminiAdapter::RetryableError) do
      adapter.analyze(source_url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ", output_language: "pl")
    end

    assert_equal "Quota exceeded.", error.message
    assert_in_delta 47.160335681, error.retry_after_seconds, 0.000001
  end

  test "reads a quota retry delay from Gemini's current error message" do
    response = Response.new(
      {
        error: {
          message: "Quota exceeded. Please retry in 53.493918152s.",
          code: "too_many_requests"
        }
      }.to_json,
      "429"
    )
    adapter = TimeoutGeminiAdapter.new(response)

    error = assert_raises(GeminiAdapter::RetryableError) do
      adapter.analyze(source_url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ", output_language: "pl")
    end

    assert_in_delta 53.493918152, error.retry_after_seconds, 0.000001
  end

  test "treats an incomplete successful response as a retryable provider failure" do
    adapter = GeminiAdapter.new
    response = successful_response(source_title: "")

    error = with_gemini_api_key do
      assert_raises(GeminiAdapter::RetryableError) do
        capture_http_request(response) do
          adapter.analyze(source_url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ", output_language: "pl")
        end
      end
    end

    assert_equal "Gemini returned an invalid Brief. Please try again.", error.message
  end

  test "treats malformed nested response content as a retryable provider failure" do
    adapter = GeminiAdapter.new
    response = successful_response(structured_content: nil)

    error = with_gemini_api_key do
      assert_raises(GeminiAdapter::RetryableError) do
        capture_http_request(response) do
          adapter.analyze(source_url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ", output_language: "pl")
        end
      end
    end

    assert_equal "Gemini returned an invalid Brief. Please try again.", error.message
  end

  test "treats a non-object successful response envelope as a retryable provider failure" do
    adapter = GeminiAdapter.new
    response = SuccessfulResponse.new("[]")

    error = with_gemini_api_key do
      assert_raises(GeminiAdapter::RetryableError) do
        capture_http_request(response) do
          adapter.analyze(source_url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ", output_language: "pl")
        end
      end
    end

    assert_equal "Gemini returned an unreadable Brief response.", error.message
  end

  test "treats a non-object error response envelope as a retryable provider failure" do
    adapter = TimeoutGeminiAdapter.new(Response.new("[]", "500"))

    error = assert_raises(GeminiAdapter::RetryableError) do
      adapter.analyze(source_url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ", output_language: "pl")
    end

    assert_equal "Gemini returned an unreadable Brief response.", error.message
  end

  test "treats malformed error details as a retryable provider failure" do
    adapter = TimeoutGeminiAdapter.new(Response.new('{"error":"unavailable"}', "500"))

    error = assert_raises(GeminiAdapter::RetryableError) do
      adapter.analyze(source_url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ", output_language: "pl")
    end

    assert_equal "Gemini did not complete the analysis.", error.message
  end

  test "treats a null output text as a retryable provider failure" do
    adapter = GeminiAdapter.new
    response = SuccessfulResponse.new('{"output_text":null}')

    error = with_gemini_api_key do
      assert_raises(GeminiAdapter::RetryableError) do
        capture_http_request(response) do
          adapter.analyze(source_url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ", output_language: "pl")
        end
      end
    end

    assert_equal "Gemini returned an unreadable Brief response.", error.message
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

  def successful_response(**overrides)
    generated_brief = {
      source_title: "Source title",
      source_channel: "Source channel",
      published_on: "2026-08-20",
      duration_seconds: 60,
      content_markdown: "# Brief",
      structured_content: { sections: [ { heading: "Details", body: "Source details." } ] },
      key_conclusions: [ "One.", "Two.", "Three.", "Four.", "Five." ]
    }.merge(overrides)
    SuccessfulResponse.new({ output_text: generated_brief.to_json }.to_json)
  end

  def successful_steps_response
    generated_brief = {
      source_title: "Source title",
      source_channel: "Source channel",
      published_on: "2026-08-20",
      duration_seconds: 60,
      content_markdown: "# Brief",
      structured_content: { sections: [ { heading: "Details", body: "Source details." } ] },
      key_conclusions: [ "One.", "Two.", "Three.", "Four.", "Five." ]
    }
    SuccessfulResponse.new(
      {
        steps: [
          { type: "user_input", content: [ { type: "text", text: "Ignore this." } ] },
          { type: "model_output", content: [ { type: "text", text: generated_brief.to_json } ] }
        ]
      }.to_json
    )
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
