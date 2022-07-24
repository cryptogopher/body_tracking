class MeasurementsController < ApplicationController
  layout 'body_tracking'
  menu_item :body_trackers
  helper :body_trackers

  include Concerns::Finders

  before_action :init_session_filters
  before_action :find_project_by_project_id, only: [:index, :new, :create, :filter]
  before_action :find_measurement, only: [:edit, :update, :destroy, :retake]
  before_action :find_measurement_routine_by_measurement_routine_id,
    only: [:new, :create, :filter]
  before_action :authorize
  before_action :set_view_params

  def index
    prepare_measurements
  end

  def new
    @measurement = @project.measurements.new
    @measurement.build_routine
    @measurement.readouts.new
  end

  def create
    # Nested attributes cannot create outer object (Measurement) and at the same time edit
    # existing nested object (MeasurementRoutine) if it's not associated with outer object
    # https://stackoverflow.com/questions/6346134/
    # That's why Routine needs to be found and associated before Measurement initialization
    @measurement = @project.measurements.new
    update_routine_from_params
    @measurement.attributes = measurement_params
    @measurement.routine.project = @project
    if @measurement.save
      routine = @measurement.routine
      if routine.readout_exposures.empty?
        routine.quantities << @measurement.readouts.map(&:quantity).first(6)
      end

      flash.now[:notice] = 'Created new measurement'
      prepare_items
    else
      @measurement.readouts.new if @measurement.readouts.empty?
      render :new
    end
  end

  def edit
  end

  def update
    update_routine_from_params
    if @measurement.update(measurement_params)
      if @measurement.routine.previous_changes.has_key?(:name) && @routine
        flash[:notice] = 'Updated measurement'
        render js: "window.location.pathname='#{readouts_measurement_routine_path(@routine)}'"
      else
        flash.now[:notice] = 'Updated measurement'
        prepare_items
        render :index
      end
    else
      render :edit
    end
  end

  def destroy
    if @measurement.destroy
      flash.now[:notice] = 'Deleted measurement'
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

  def filter
    session[:m_filters] = params.permit(:name, formula: [:code, :zero_nil])
    prepare_items
    render :index
  end

  private

  def init_session_filters
    session[:m_filters] ||= {formula: {}}
  end

  def measurement_params
    params.require(:measurement).permit(
      :notes,
      :source_id,
      routine_attributes:
      [
        :id,
        :name,
        :description
      ],
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

  def update_routine_from_params
    routine_id = params[:measurement][:routine_attributes][:id]
    return unless routine_id
    @measurement.routine = @project.measurement_routines.find_by(id: routine_id)
  end

  def prepare_items
    @routine ? prepare_readouts : prepare_measurements
  end

  def prepare_measurements
    @measurements, @filter_q = @project.measurements.includes(:routine, :source, :readouts)
      .filter(session[:m_filters])
  end

  def set_view_params
    @view_params =
      if @routine
        {view: :readouts, measurement_routine_id: @routine.id}
      else
        {view: :index}
      end
  end
end
