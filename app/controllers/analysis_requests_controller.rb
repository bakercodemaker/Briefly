class AnalysisRequestsController < ApplicationController
  before_action :require_workspace_access

  def create
    @analysis_request = AnalysisRequest.new(analysis_request_params)

    if @analysis_request.save
      session[:active_analysis_request_id] = @analysis_request.id
      GenerateBriefJob.perform_later(@analysis_request.id)
      redirect_to workspace_path, notice: "Analysis request queued."
    else
      @analysis_requests = AnalysisRequest.order(created_at: :desc)
      render "workspace/show", status: :unprocessable_entity
    end
  end

  def retry
    analysis_request = AnalysisRequest.find(params[:id])

    if analysis_request.retry_after_recoverable_failure!
      GenerateBriefJob.perform_later(analysis_request.id)
      redirect_to workspace_path, notice: "Analysis request queued for another attempt."
    else
      redirect_to workspace_path, alert: "This analysis request cannot be retried."
    end
  end

  private

  def analysis_request_params
    params.require(:analysis_request).permit(:source_url)
  end
end
