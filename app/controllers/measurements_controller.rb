class MeasurementsController < ApplicationController
  menu_item :body_trackers

  before_action :init_session_filters
  before_action :find_project_by_project_id, only: [:index, :new, :create]
  before_action :find_quantity, only: [:toggle_quantity]
  before_action :find_measurement, only: [:edit, :update, :destroy, :retake, :readouts]
  before_action :authorize

  def index
    session[:m_filters][:scope] = {}
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
      prepare_measurements
      render :index
    else
      render :edit
    end
  end

  def destroy
    if @measurement.destroy
      flash[:notice] = 'Deleted measurement'
    end
  end

  def retake
    readouts = @measurement.readouts.map(&:dup)
    @measurement = @measurement.dup
    @measurement.readouts = readouts
    @measurement.taken_at = Time.now
    @measurement.readouts.each { |r| r.value = nil }
    render :new
  end

  def readouts
    session[:m_filters][:scope] = {name: @measurement.name}
    prepare_readouts
  end

  def toggle_quantity
    @quantity.toggle_primary!
    prepare_readouts
  end

  private

  def init_session_filters
    session[:m_filters] ||= {}
  end

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
    @measurements, @formula_q = @project.measurements
      .includes(:source, :readouts)
      .filter(session[:m_filters])
  end

  def prepare_readouts
    @quantities = @project.quantities.measurement.where(primary: true)
    @measurements, @requested_r, @extra_r, @formula_q = @project.measurements
      .includes(:source)
      .filter(session[:m_filters], @quantities)
  end
end
