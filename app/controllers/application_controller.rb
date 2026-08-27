class ApplicationController < ActionController::Base
  include WorkspaceViewState
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private

  def require_workspace_access
    unless session[:workspace_access]
      reset_session
      redirect_to(access_path)
    end
  end
end
