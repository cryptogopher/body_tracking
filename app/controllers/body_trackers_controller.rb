class BodyTrackersController < ApplicationController
  before_action :find_project, only: [:index]
  before_action :authorize

  def index
  end

  private

  # :find_* methods are called before :authorize,
  # @project is required for :authorize to succeed
  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
