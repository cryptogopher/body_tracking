class MeasurementsController < ApplicationController
  layout 'body_tracking'
  menu_item :body_trackers
  helper :body_trackers

  include Concerns::Finders

  before_action :init_session_filters
  before_action :find_project_by_project_id, only: [:index, :new, :create, :filter]
  before_action :find_quantity_by_quantity_id, only: [:toggle_column]
  before_action :find_measurement, only: [:edit, :update, :destroy, :retake]
  before_action :find_measurement_routine, only: [:readouts, :toggle_column]
  before_action :authorize

  def index
    prepare_measurements
  end

  def new
    @measurement = @project.measurements.new
    @measurement.build_routine
    @measurement.readouts.new
  end

  def create
    @measurement = @project.measurements.new(measurement_params)
    @measurement.routine.project = @project
    if @measurement.save
      if @measurement.routine.columns.empty?
        @measurement.routine.quantities << @measurement.readouts.map(&:quantity).first(6)
      end

      flash[:notice] = 'Created new measurement'
      prepare_items
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
      prepare_items
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
    prepare_readouts
  end

  def toggle_column
    @routine.columns.toggle!(@quantity)
    prepare_readouts
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

  def prepare_items
    params[:view] == 'index' ? prepare_measurements : prepare_readouts
  end

  def prepare_measurements
    @measurements, @formula_q = @project.measurements
      .includes(:routine, :source, :readouts)
      .filter(session[:m_filters])
  end

  def prepare_readouts
    @quantities = @measurement.routine.quantities.includes(:formula)
    @measurements, @requested_r, @extra_r, @formula_q = @routine.measurements
      .includes(:routine, :source)
      .filter(session[:m_filters], @quantities)
  end
end
