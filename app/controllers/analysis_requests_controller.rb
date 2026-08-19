class AnalysisRequestsController < ApplicationController
  before_action :require_workspace_access

  def create
    @analysis_request = AnalysisRequest.new(analysis_request_params)

    if @analysis_request.save
      redirect_to workspace_path, notice: "Analysis request queued."
    else
      @analysis_requests = AnalysisRequest.order(created_at: :desc)
      render "workspace/show", status: :unprocessable_entity
    end
  end

  private

  def analysis_request_params
    params.require(:analysis_request).permit(:source_url)
  end

  def require_workspace_access
    redirect_to access_path unless session[:workspace_access]
  end
end
