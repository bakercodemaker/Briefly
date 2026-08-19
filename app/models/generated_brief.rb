class GeneratedBrief
  ATTRIBUTES = %i[
    source_url
    source_title
    source_channel
    published_on
    duration_seconds
    output_language
    content_markdown
    structured_content
    key_conclusions
  ].freeze

  attr_reader(*ATTRIBUTES)

  def initialize(**attributes)
    attributes.assert_valid_keys(*ATTRIBUTES)
    ATTRIBUTES.each { |attribute| instance_variable_set("@#{attribute}", attributes.fetch(attribute)) }
  end

  def to_h
    ATTRIBUTES.index_with { |attribute| public_send(attribute) }
  end
end
