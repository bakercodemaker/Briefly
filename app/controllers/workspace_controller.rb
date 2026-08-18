class WorkspaceController < ApplicationController
  before_action :require_workspace_access

  def show
  end

  private

  def require_workspace_access
    redirect_to access_path unless session[:workspace_access]
  end
end
