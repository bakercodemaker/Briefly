class WorkspaceController < ApplicationController
  before_action :require_workspace_access

  def show
    @open_brief = Brief.find_by(id: params[:brief_id])

    if @open_brief.nil? && (brief = Brief.find_by(analysis_request_id: session[:active_analysis_request_id]))
      session.delete(:active_analysis_request_id)
      redirect_to workspace_path(brief_id: brief.id)
      return
    end

    assign_workspace_view_state(
      analysis_request: AnalysisRequest.new,
      expanded: params[:show_all_requests] == "1" || params[:requests_page].present?,
      page: params.fetch(:requests_page, 1)
    )
  end
end
