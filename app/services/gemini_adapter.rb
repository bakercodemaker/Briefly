require "json"
require "net/http"

class GeminiAdapter
  class Error < StandardError; end

  INTERACTIONS_URI = URI("https://generativelanguage.googleapis.com/v1beta/interactions")

  def analyze(source_url:, output_language:)
    response = post_interaction(source_url:, output_language:)
    response_body = JSON.parse(response.body)
    raise Error, response_body.dig("error", "message") || "Gemini did not complete the analysis." unless response.is_a?(Net::HTTPSuccess)

    generated_brief_from(JSON.parse(response_body.fetch("output_text")), source_url:, output_language:)
  rescue JSON::ParserError, KeyError, ArgumentError => error
    raise Error, "Gemini returned an unreadable Brief: #{error.message}"
  end

  private

  def post_interaction(source_url:, output_language:)
    request = Net::HTTP::Post.new(INTERACTIONS_URI)
    request["x-goog-api-key"] = ENV.fetch("GEMINI_API_KEY")
    request["Content-Type"] = "application/json"
    request.body = JSON.generate(
      model: ENV.fetch("GEMINI_MODEL", "gemini-3.7-flash"),
      input: [
        { type: "text", text: prompt(output_language) },
        { type: "video", uri: source_url }
      ],
      response_format: { type: "text", mime_type: "application/json", schema: response_schema }
    )

    Net::HTTP.start(INTERACTIONS_URI.host, INTERACTIONS_URI.port, use_ssl: true, open_timeout: 10, read_timeout: 120) do |http|
      http.request(request)
    end
  end

  def prompt(output_language)
    <<~PROMPT
      Create a detailed, source-faithful Brief in #{output_language}. Use only the supplied public YouTube video.
      Preserve concrete claims, figures, names, caveats, and reasoning. Do not add fact checking, outside context, or advice.
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
        key_conclusions: { type: "array", items: { type: "string" } }
      },
      required: %w[source_title source_channel published_on duration_seconds content_markdown structured_content key_conclusions]
    }
  end

  def generated_brief_from(response, source_url:, output_language:)
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
end
