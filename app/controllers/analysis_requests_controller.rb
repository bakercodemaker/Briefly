class AnalysisRequestsController < ApplicationController
  before_action :require_workspace_access

  def create
    @analysis_request = AnalysisRequest.new(analysis_request_params)

    if @analysis_request.invalid?
      render_invalid_workspace_request
    elsif !GeminiAdapter.configured?
      @analysis_request.errors.add(:base, GeminiAdapter::NOT_CONFIGURED_MESSAGE)
      render_invalid_workspace_request
    elsif AnalysisRequest.reserve_active_request_slot { @analysis_request.save }
      session[:active_analysis_request_id] = @analysis_request.id
      GenerateBriefJob.perform_later(@analysis_request.id)
      redirect_to workspace_path, notice: "Analysis request queued."
    else
      @analysis_request.errors.add(:base, "Wait for an active analysis request to finish before queueing another.")
      render_invalid_workspace_request
    end
  end

  def retry
    analysis_request = AnalysisRequest.find(params[:id])

    if !GeminiAdapter.configured?
      redirect_to workspace_path, alert: GeminiAdapter::NOT_CONFIGURED_MESSAGE
    elsif AnalysisRequest.reserve_active_request_slot { analysis_request.retry_after_recoverable_failure! }
      GenerateBriefJob.perform_later(analysis_request.id)
      redirect_to workspace_path, notice: "Analysis request queued for another attempt."
    else
      redirect_to workspace_path, alert: "This analysis request cannot be retried."
    end
  end

  def archive
    analysis_request = AnalysisRequest.find(params[:id])
    analysis_request.archive!

    redirect_to workspace_path, notice: "Analysis request archived."
  end

  private

  def analysis_request_params
    params.require(:analysis_request).permit(:source_url)
  end

  def render_invalid_workspace_request
    assign_workspace_view_state(analysis_request: @analysis_request, expanded: false, page: 1)
    render "workspace/show", status: :unprocessable_entity
  end
end
