require "json"
require "net/http"

class GeminiAdapter
  INVALID_BRIEF_MESSAGE = "Gemini returned an invalid Brief. Please try again."
  UNREADABLE_RESPONSE_MESSAGE = "Gemini returned an unreadable Brief response."

  class Error < StandardError; end
  class TerminalError < Error; end
  class RetryableError < Error; end

  INTERACTIONS_URI = URI("https://generativelanguage.googleapis.com/v1beta/interactions")

  def analyze(source_url:, output_language:)
    response = post_interaction(source_url:, output_language:)
    response_body = response_body_from(response)
    raise provider_error(response, response_body) unless response.is_a?(Net::HTTPSuccess)

    output_text = response_body["output_text"]
    raise RetryableError, UNREADABLE_RESPONSE_MESSAGE unless output_text.is_a?(String)

    generated_brief_from(JSON.parse(output_text), source_url:, output_language:)
  rescue JSON::ParserError, KeyError, ArgumentError => error
    raise RetryableError, "Gemini returned an unreadable Brief: #{error.message}"
  rescue Net::OpenTimeout, Net::ReadTimeout, SocketError => error
    raise RetryableError, "Gemini is temporarily unavailable: #{error.message}"
  end

  private

  def response_body_from(response)
    response_body = JSON.parse(response.body)
    raise RetryableError, UNREADABLE_RESPONSE_MESSAGE unless response_body.is_a?(Hash)

    response_body
  end

  def post_interaction(source_url:, output_language:)
    request = Net::HTTP::Post.new(INTERACTIONS_URI)
    request["x-goog-api-key"] = ENV.fetch("GEMINI_API_KEY")
    request["Content-Type"] = "application/json"
    model = ENV.fetch("GEMINI_MODEL", "gemini-3.7-flash")
    request.body = JSON.generate(
      model:,
      input: [
        { type: "text", text: prompt(output_language) },
        { type: "video", uri: source_url }
      ],
      response_format: { type: "text", mime_type: "application/json", schema: response_schema }
    )

    Rails.logger.info("gemini.request model=#{model}")
    Net::HTTP.start(INTERACTIONS_URI.host, INTERACTIONS_URI.port, use_ssl: true, open_timeout: 10, read_timeout: 120) do |http|
      response = http.request(request)
      Rails.logger.info("gemini.response status=#{response.code}")
      response
    end
  end

  def provider_error(response, response_body)
    error_details = response_body["error"]
    message = error_details["message"] if error_details.is_a?(Hash)
    message ||= "Gemini did not complete the analysis."
    return RetryableError.new(message) if [ 408, 429 ].include?(response.code.to_i) || response.code.to_i >= 500

    TerminalError.new(message)
  end

  def prompt(output_language)
    <<~PROMPT
      Create a detailed, source-faithful Brief in #{output_language}. Use only the supplied public YouTube video.
      Preserve concrete claims, figures, names, caveats, attribution, uncertainty, and reasoning. Do not add fact checking, outside context, or advice.
      Return five to ten concise key conclusions and thematic sections with detailed prose.
    PROMPT
  end

  def response_schema
    {
      type: "object",
      properties: {
        source_title: { type: "string" },
        source_channel: { type: "string" },
        published_on: { type: "string", description: "ISO 8601 publication date" },
        duration_seconds: { type: "integer" },
        content_markdown: { type: "string", description: "The complete Brief in Markdown" },
        structured_content: {
          type: "object",
          properties: {
            sections: {
              type: "array",
              items: {
                type: "object",
                properties: { heading: { type: "string" }, body: { type: "string" } },
                required: %w[heading body]
              }
            }
          },
          required: [ "sections" ]
        },
        key_conclusions: { type: "array", minItems: 5, maxItems: 10, items: { type: "string" } }
      },
      required: %w[source_title source_channel published_on duration_seconds content_markdown structured_content key_conclusions]
    }
  end

  def generated_brief_from(response, source_url:, output_language:)
    validate_generated_brief!(response)

    GeneratedBrief.new(
      source_url: source_url,
      source_title: response.fetch("source_title"),
      source_channel: response.fetch("source_channel"),
      published_on: Date.iso8601(response.fetch("published_on")),
      duration_seconds: response.fetch("duration_seconds"),
      output_language: output_language,
      content_markdown: response.fetch("content_markdown"),
      structured_content: response.fetch("structured_content"),
      key_conclusions: response.fetch("key_conclusions")
    )
  end

  def validate_generated_brief!(response)
    raise RetryableError, INVALID_BRIEF_MESSAGE unless response.is_a?(Hash)

    required_text = %w[source_title source_channel content_markdown]
    structured_content = response["structured_content"]
    sections = structured_content["sections"] if structured_content.is_a?(Hash)
    conclusions = response["key_conclusions"]

    return if required_text.all? { |field| response[field].present? } &&
      response["published_on"].present? &&
      response["duration_seconds"].is_a?(Integer) && response["duration_seconds"].positive? &&
      valid_sections?(sections) && valid_conclusions?(conclusions)

    raise RetryableError, INVALID_BRIEF_MESSAGE
  end

  def valid_sections?(sections)
    sections.is_a?(Array) && sections.any? && sections.all? do |section|
      section.is_a?(Hash) && section.fetch("heading").present? && section.fetch("body").present?
    end
  rescue KeyError
    false
  end

  def valid_conclusions?(conclusions)
    conclusions.is_a?(Array) && conclusions.length.between?(5, 10) && conclusions.all?(&:present?)
  end
end
