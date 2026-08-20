class DemoLibraryController < ApplicationController
  def show
    @briefs = Brief.public_demo.order(created_at: :desc)
  end

  def brief
    @brief = Brief.public_demo.find(params[:id])
  end
end
