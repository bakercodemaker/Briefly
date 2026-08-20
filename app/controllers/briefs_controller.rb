class BriefsController < ApplicationController
  before_action :require_workspace_access

  def show
    @brief = Brief.find(params[:id])
  end

  def archive
    Brief.find(params[:id]).analysis_request.archive!
    redirect_to workspace_path, notice: "Brief archived."
  end

  def archived
    @briefs = Brief.archived.order(created_at: :desc)
  end
end
