class WorkspaceController < ApplicationController
  before_action :require_workspace_access

  def show
    @open_brief = Brief.find_by(id: params[:brief_id])

    if @open_brief.nil? && (brief = Brief.find_by(analysis_request_id: session[:active_analysis_request_id]))
      session.delete(:active_analysis_request_id)
      redirect_to workspace_path(brief_id: brief.id)
      return
    end

    @analysis_request = AnalysisRequest.new
    @analysis_requests = AnalysisRequest.order(created_at: :desc)
    @briefs_by_channel = Brief.completed_by_channel
  end
end
