demo_briefs = [
  [ "https://www.youtube.com/watch?v=eIho2S0ZahI", "How to Speak So That People Want to Listen", Date.new(2014, 6, 27), 599,
    [ "Julian Treasure frames conscious listening as a prerequisite for meaningful speaking.", "He contrasts damaging speaking habits with honesty, authenticity, integrity, and love.", "The talk describes vocal register, timbre, prosody, pace, pitch, and volume as speaking tools.", "Treasure demonstrates short warm-up exercises for voice, breath, and articulation.", "He closes with a vision of more conscious sound and speech." ],
    [ [ "Listening and intention", "Treasure presents listening as a skill that can be practised and as the context that gives speech its value." ], [ "Habits and vocal tools", "The talk names habits that make listeners withdraw, then describes HAIL and practical vocal variables." ] ] ],
  [ "https://www.youtube.com/watch?v=RcGyVTAoXEU", "How to Make Stress Your Friend", Date.new(2013, 9, 4), 886,
    [ "Kelly McGonigal questions the assumption that stress is inevitably harmful.", "She recounts research linking beliefs about stress with health outcomes.", "The talk interprets stress responses as preparing the body to meet a challenge.", "McGonigal highlights oxytocin and connects it with reaching out to others.", "Her conclusion is an invitation to change one’s relationship with stress." ],
    [ [ "A different interpretation", "McGonigal revisits her earlier advice to reduce stress in light of research she presents about beliefs and stress." ], [ "Connection under pressure", "She describes the social side of the stress response and the place of caring for others and asking for support." ] ] ],
  [ "https://www.youtube.com/watch?v=D9Ihs241zeg", "The Danger of a Single Story", Date.new(2009, 10, 7), 1126,
    [ "Chimamanda Ngozi Adichie uses personal stories to show how incomplete narratives shape expectations.", "A single story can make one group appear as only one thing.", "The talk links storytelling with power: who tells stories and which stories circulate matters.", "A story can contain truth without being the only available account.", "Many stories restore complexity and dignity." ],
    [ [ "Stories formed early", "Adichie recounts reading and writing experiences from childhood to show how available stories shaped what she imagined." ], [ "Power and complexity", "Through encounters in Nigeria and the United States, she explains how simplified narratives create misunderstanding and argues for many stories." ] ] ]
].freeze

demo_briefs.each do |source_url, source_title, published_on, duration_seconds, key_conclusions, sections|
  next if Brief.exists?(source_url:, publicly_visible: true)

  analysis_request = AnalysisRequest.create!(source_url:, lifecycle_state: "completed")
  Brief.create!(
    analysis_request:,
    source_url:,
    source_title:,
    source_channel: "TED",
    published_on:,
    duration_seconds:,
    output_language: "en",
    content_markdown: sections.map { |heading, body| "## #{heading}\n\n#{body}" }.join("\n\n"),
    structured_content: { "sections" => sections.map { |heading, body| { "heading" => heading, "body" => body } } },
    key_conclusions:,
    publicly_visible: true
  )
end
