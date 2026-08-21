class AccessController < ApplicationController
  ACCESS_RATE_LIMIT_STORE = ActiveSupport::Cache::MemoryStore.new

  rate_limit to: 5,
    within: 15.minutes,
    only: :create,
    store: ACCESS_RATE_LIMIT_STORE,
    with: -> {
      flash.now[:alert] = "Too many unlock attempts. Try again later."
      render :new, status: :too_many_requests
    }

  def new
  end

  def create
    if owner_password_matches?
      reset_session
      session[:workspace_access] = true
      session[:workspace_authenticated_at] = Time.current.to_i
      session[:workspace_last_seen_at] = Time.current.to_i
      redirect_to workspace_path, notice: "Personal Workspace unlocked."
    else
      flash.now[:alert] = "That password does not unlock the Personal Workspace."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "Personal Workspace locked."
  end

  private

  def owner_password_matches?
    expected_password = ENV.fetch("OWNER_PASSWORD")
    submitted_password = params[:password].to_s

    submitted_password.bytesize == expected_password.bytesize &&
      ActiveSupport::SecurityUtils.secure_compare(submitted_password, expected_password)
  end
end
