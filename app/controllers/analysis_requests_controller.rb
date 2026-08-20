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
      @analysis_request_count = @analysis_requests.count
      @analysis_requests_expanded = false
      @analysis_requests_page = 1
      @analysis_requests_total_pages = (@analysis_request_count / 10.0).ceil
      @display_analysis_requests = @analysis_requests.limit(3)
      @briefs_by_channel = Brief.completed_by_channel
      @archived_brief_count = Brief.archived.count
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

  def archive
    analysis_request = AnalysisRequest.find(params[:id])
    analysis_request.archive!

    redirect_to workspace_path, notice: "Analysis request archived."
  end

  private

  def analysis_request_params
    params.require(:analysis_request).permit(:source_url)
  end
end
