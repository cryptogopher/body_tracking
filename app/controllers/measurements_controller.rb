class MeasurementsController < ApplicationController
  menu_item :body_trackers

  before_action :find_project_by_project_id, only: [:index, :new, :create]
  before_action :find_measurement, only: [:edit, :update, :destroy, :retake]
  before_action :authorize

  def index
    prepare_measurements
  end

  def new
    @measurement = @project.measurements.new
    @measurement.readouts.new
  end

  def create
    @measurement = @project.measurements.new(measurement_params)
    if @measurement.save
      flash[:notice] = 'Created new measurement'
      prepare_measurements
    else
      @measurement.readouts.new if @measurement.readouts.empty?
      render :new
    end
  end

  def edit
  end

  def update
    if @measurement.update(measurement_params)
      flash[:notice] = 'Updated measurement'
    end
    prepare_measurements
    render :index
  end

  def destroy
    if @measurement.destroy
      flash[:notice] = 'Deleted measurement'
    end
    prepare_measurements
    render :index
  end

  def retake
    @measurement = @measurement.dup
    prepare_measurements
    redirect_to project_measurements_path(@project)
  end

  private

  def measurement_params
    params.require(:measurement).permit(
      :name,
      :source_id,
      readouts_attributes:
      [
        :id,
        :quantity_id,
        :value,
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
    @measurements = @project.measurements.includes(:source, :readouts)
  end
end
