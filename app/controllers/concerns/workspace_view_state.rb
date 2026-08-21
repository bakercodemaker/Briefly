module WorkspaceViewState
  private

  def assign_workspace_view_state(analysis_request:, expanded:, page:)
    @analysis_request = analysis_request
    @analysis_requests = AnalysisRequest.active.newest_first
    @analysis_request_count = @analysis_requests.count
    @analysis_requests_expanded = expanded
    @analysis_requests_page = [ page.to_i, 1 ].max
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
