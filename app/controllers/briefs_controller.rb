class BriefsController < ApplicationController
  before_action :require_workspace_access

  def show
    @brief = Brief.find(params[:id])
  end

  def destroy
    Brief.find(params[:id]).destroy!
    redirect_to workspace_path, notice: "Brief deleted. You can create a new Analysis Request whenever you need it."
  end
end
