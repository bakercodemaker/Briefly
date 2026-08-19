class WorkspaceController < ApplicationController
  before_action :require_workspace_access

  def show
    @analysis_request = AnalysisRequest.new
    @analysis_requests = AnalysisRequest.order(created_at: :desc)
  end

  private

  def require_workspace_access
    redirect_to access_path unless session[:workspace_access]
  end
end
