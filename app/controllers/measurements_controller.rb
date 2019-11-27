class MeasurementsController < ApplicationController
  menu_item :body_trackers

  before_action :find_project_by_project_id, only: [:index, :create]
  before_action :find_measurement, only: [:destroy, :toggle]
  before_action :authorize

  def index
    @measurement = @project.measurements.new
    @measurement.readouts.new

    prepare_measurements
    @measurements << @measurement
  end

  def create
    @measurement = @project.measurements.new(measurement_params)
    if @measurement.save
      flash[:notice] = 'Created newmeasurement'
      redirect_to :back
    else
      prepare_measurements
      @measurement.readouts.new if @measurement.readouts.empty?
      render :index
    end
  end

  def destroy
    # FIXME: don't destroy if there are any readout values
    if @measurement.destroy
      flash[:notice] = 'Deleted measurement'
    end
    prepare_measurements
    render :toggle
  end

  def toggle
    @measurement.toggle_hidden!
    prepare_measurements
  end

  private

  def ingredient_params
    params.require(:measurement).permit(
      :name,
      :source_id,
      readouts_attributes:
      [
        :id,
        :quantity_id,
        :unit_id,
        :_destroy
      ]
    )
  end

  # :find_* methods are called before :authorize,
  # @project is required for :authorize to succeed
  def find_measurement
    @measurement = Measurement.find(params[:id])
    @project = @measurement.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def prepare_measurements
    @measurements = @project.measurements.includes(:source)
  end
end
