class UnitsController < ApplicationController
  before_action :find_project, only: [:new, :index, :create]
  before_action :authorize

  def new
    @unit = Unit.new
  end

  def index
    @unit = Unit.new
  end

  def create
  end

  def destroy
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
