class AccessController < ApplicationController
  def new
  end

  def create
    if owner_password_matches?
      session[:workspace_access] = true
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
