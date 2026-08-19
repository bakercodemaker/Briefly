class BriefsController < ApplicationController
  before_action :require_workspace_access

  def show
    @brief = Brief.find(params[:id])
  end
end
