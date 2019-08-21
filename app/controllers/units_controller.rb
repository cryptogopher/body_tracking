class UnitsController < ApplicationController
  before_action :find_project, only: [:index, :create, :import]
  before_action :authorize

  def index
    @unit = Unit.new
    @units = @project.units
  end

  def create
  end

  def destroy
  end

  def import
    defaults = Unit.where(project: nil).pluck(:name, :shortname)
    missing = defaults - Unit.where(project: @project).pluck(:name, :shortname)
    @project.units.create(missing.map { |n, s| {name: n, shortname: s} })

    redirect_to project_units_url(@project)
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
