class UnitsController < ApplicationController
  before_action :find_project, only: [:index, :create, :import]
  before_action :find_unit, only: [:destroy]
  before_action :authorize

  def index
    @unit = Unit.new
    @units = @project.units
  end

  def create
    @unit = Unit.new(unit_params.update(project: @project))
    if @unit.save
      flash[:notice] = 'Created new unit'
      redirect_to project_units_url(@project)
    else
      @units = @project.units
      render :index
    end
  end

  def destroy
    if @unit.destroy
      flash[:notice] = 'Deleted unit'
    end
    redirect_to project_units_url(@project)
  end

  def import
    defaults = Unit.where(project: nil).pluck(:name, :shortname)
    missing = defaults - Unit.where(project: @project).pluck(:name, :shortname)
    @project.units.create(missing.map { |n, s| {name: n, shortname: s} })

    redirect_to project_units_url(@project)
  end

  private

  def unit_params
    params.require(:unit).permit(
      :name,
      :shortname
    )
  end

  # :find_* methods are called before :authorize,
  # @project is required for :authorize to succeed
  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_unit
    @unit = Unit.find(params[:id])
    @project = @unit.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
