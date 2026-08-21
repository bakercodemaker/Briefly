class ApplicationController < ActionController::Base
  include WorkspaceViewState
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private

  WORKSPACE_IDLE_TIMEOUT = 30.minutes
  WORKSPACE_ABSOLUTE_TIMEOUT = 12.hours

  def require_workspace_access
    unless valid_workspace_session?
      reset_session
      return redirect_to(access_path)
    end

    session[:workspace_last_seen_at] = Time.current.to_i
  end

  def valid_workspace_session?
    authenticated_at = session[:workspace_authenticated_at].to_i
    last_seen_at = session[:workspace_last_seen_at].to_i
    session[:workspace_access] &&
      authenticated_at.positive? &&
      last_seen_at.positive? &&
      authenticated_at >= WORKSPACE_ABSOLUTE_TIMEOUT.ago.to_i &&
      last_seen_at >= WORKSPACE_IDLE_TIMEOUT.ago.to_i
  end
end
