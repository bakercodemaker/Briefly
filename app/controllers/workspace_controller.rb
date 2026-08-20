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
    @analysis_requests = AnalysisRequest.active.newest_first
    @analysis_request_count = @analysis_requests.count
    @analysis_requests_expanded = params[:show_all_requests] == "1" || params[:requests_page].present?
    @analysis_requests_page = [ params.fetch(:requests_page, 1).to_i, 1 ].max
    @analysis_requests_total_pages = (@analysis_request_count / 10.0).ceil
    @display_analysis_requests = if @analysis_requests_expanded
      @analysis_requests.offset((@analysis_requests_page - 1) * 10).limit(10)
    else
      @analysis_requests.limit(3)
    end
    @briefs_by_channel = Brief.completed_by_channel
    @archived_brief_count = Brief.archived.count
  end
end
