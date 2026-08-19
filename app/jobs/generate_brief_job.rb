class GenerateBriefJob < ApplicationJob
  MAX_AUTOMATIC_RETRIES = 2

  def perform(analysis_request_id)
    return unless claim_queued_request(analysis_request_id)

    analysis_request = AnalysisRequest.find(analysis_request_id)
    generated_brief = gemini_adapter.analyze(source_url: analysis_request.source_url, output_language: "pl")

    AnalysisRequest.transaction do
      analysis_request.create_brief!(generated_brief.to_h.merge(source_url: analysis_request.source_url, output_language: "pl"))
      analysis_request.update!(lifecycle_state: "completed")
    end
  rescue GeminiAdapter::RetryableError => error
    handle_retryable_failure(analysis_request_id, error)
  rescue GeminiAdapter::Error => error
    fail_request(analysis_request_id, error.message, recoverable: false)
  end

  private

  def claim_queued_request(analysis_request_id)
    AnalysisRequest.where(id: analysis_request_id, lifecycle_state: "queued").update_all(lifecycle_state: "processing", updated_at: Time.current) == 1
  end

  def gemini_adapter
    Rails.configuration.x.gemini_adapter ||= GeminiAdapter.new
  end

  def handle_retryable_failure(analysis_request_id, error)
    analysis_request = AnalysisRequest.find(analysis_request_id)

    if analysis_request.automatic_retry_count < MAX_AUTOMATIC_RETRIES
      analysis_request.update!(
        lifecycle_state: "queued",
        automatic_retry_count: analysis_request.automatic_retry_count + 1,
        recoverable_failure: true,
        failure_message: error.message
      )
      self.class.perform_later(analysis_request.id)
    else
      fail_request(analysis_request.id, error.message, recoverable: true)
    end
  end

  def fail_request(analysis_request_id, message, recoverable:)
    AnalysisRequest.where(id: analysis_request_id, lifecycle_state: "processing").update_all(
      lifecycle_state: "failed",
      recoverable_failure: recoverable,
      failure_message: message,
      updated_at: Time.current
    )
  end
end
