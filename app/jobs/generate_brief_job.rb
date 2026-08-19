class GenerateBriefJob < ApplicationJob
  def perform(analysis_request_id)
    return unless claim_queued_request(analysis_request_id)

    analysis_request = AnalysisRequest.find(analysis_request_id)
    generated_brief = gemini_adapter.analyze(source_url: analysis_request.source_url, output_language: "pl")

    AnalysisRequest.transaction do
      analysis_request.create_brief!(generated_brief.to_h.merge(source_url: analysis_request.source_url, output_language: "pl"))
      analysis_request.update!(lifecycle_state: "completed")
    end
  end

  private

  def claim_queued_request(analysis_request_id)
    AnalysisRequest.where(id: analysis_request_id, lifecycle_state: "queued").update_all(lifecycle_state: "processing", updated_at: Time.current) == 1
  end

  def gemini_adapter
    Rails.configuration.x.gemini_adapter ||= GeminiAdapter.new
  end
end
