class GenerateBriefJob < ApplicationJob
  MAX_AUTOMATIC_RETRIES = 1
  INITIAL_RETRY_DELAY = 15.seconds
  OUTPUT_LANGUAGE = "en"

  def perform(analysis_request_id)
    return unless claim_queued_request(analysis_request_id)

    analysis_request = AnalysisRequest.find(analysis_request_id)
    Rails.logger.info("brief_generation.started analysis_request_id=#{analysis_request.id}")
    generated_brief = Rails.logger.tagged("analysis_request_id=#{analysis_request.id}") do
      gemini_adapter.analyze(source_url: analysis_request.source_url, output_language: OUTPUT_LANGUAGE)
    end

    AnalysisRequest.transaction do
      analysis_request.lock!
      return if analysis_request.archived?

      analysis_request.create_brief!(generated_brief.to_h.merge(source_url: analysis_request.source_url, output_language: OUTPUT_LANGUAGE))
      analysis_request.update!(lifecycle_state: "completed", recoverable_failure: false, failure_message: nil)
    end
    Rails.logger.info("brief_generation.completed analysis_request_id=#{analysis_request.id}")
  rescue GeminiAdapter::RetryableError => error
    handle_retryable_failure(analysis_request_id, error)
  rescue GeminiAdapter::Error => error
    fail_request(analysis_request_id, error.message, recoverable: false)
  rescue ActiveRecord::RecordInvalid => error
    raise unless error.record.is_a?(Brief)

    handle_retryable_failure(
      analysis_request_id,
      GeminiAdapter::RetryableError.new(GeminiAdapter::INVALID_BRIEF_MESSAGE)
    )
  end

  private

  def claim_queued_request(analysis_request_id)
    AnalysisRequest.active.where(id: analysis_request_id, lifecycle_state: "queued").update_all(lifecycle_state: "processing", updated_at: Time.current) == 1
  end

  def gemini_adapter
    Rails.configuration.x.gemini_adapter || GeminiAdapter.new
  end

  def handle_retryable_failure(analysis_request_id, error)
    analysis_request = AnalysisRequest.find(analysis_request_id)
    Rails.logger.warn("brief_generation.retryable_failure analysis_request_id=#{analysis_request.id} retry_count=#{analysis_request.automatic_retry_count} error_class=#{error.class}")

    retry_delay = nil
    retry_requested = analysis_request.with_lock do
      next false if analysis_request.archived?

      if analysis_request.automatic_retry_count < MAX_AUTOMATIC_RETRIES
        retry_delay = error.retry_after_seconds || INITIAL_RETRY_DELAY * (2**analysis_request.automatic_retry_count)
        analysis_request.update!(
          lifecycle_state: "queued",
          automatic_retry_count: analysis_request.automatic_retry_count + 1,
          recoverable_failure: true,
          failure_message: error.message
        )
        true
      else
        false
      end
    end

    if retry_requested
      Rails.logger.info("brief_generation.retry_scheduled analysis_request_id=#{analysis_request.id} delay_seconds=#{retry_delay}")
      return self.class.set(wait: retry_delay).perform_later(analysis_request.id)
    end

    fail_request(analysis_request.id, error.message, recoverable: true) unless analysis_request.archived?
  end

  def fail_request(analysis_request_id, message, recoverable:)
    Rails.logger.warn("brief_generation.failed analysis_request_id=#{analysis_request_id} recoverable=#{recoverable}")
    AnalysisRequest.active.where(id: analysis_request_id, lifecycle_state: "processing").update_all(
      lifecycle_state: "failed",
      active_slot: nil,
      recoverable_failure: recoverable,
      failure_message: message,
      updated_at: Time.current
    )
  end
end
