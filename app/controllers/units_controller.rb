class UnitsController < ApplicationController
  menu_item :body_trackers

  before_action :find_project_by_project_id, only: [:index, :create]
  before_action :find_unit, only: [:destroy]
  before_action :authorize

  def index
    @unit = @project.units.new
    @units = @project.units
  end

  def create
    @unit = @project.units.new(unit_params)
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

  private

  def unit_params
    params.require(:unit).permit(
      :name,
      :shortname
    )
  end

  # :find_* methods are called before :authorize,
  # @project is required for :authorize to succeed
  def find_unit
    @unit = Unit.find(params[:id])
    @project = @unit.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
