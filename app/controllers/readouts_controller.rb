class ReadoutsController < ApplicationController
  layout 'body_tracking'
  menu_item :body_trackers
  helper :body_trackers

  include Concerns::Finders

  before_action :find_measurement_routine_by_measurement_routine_id,
    only: [:index, :toggle_exposure]
  before_action :find_measurement_by_measurement_id, only: [:edit, :update]
  before_action :find_quantity_by_quantity_id, only: [:toggle_exposure]
  before_action :authorize

  def index
    prepare_readouts
  end

  def edit
  end

  def update
    if @measurement.update(measurement_params)
      count = @measurement.readouts.target.count { |r| r.previous_changes.present? }
      flash.now[:notice] = t('.success', count: count)

      @routine = @measurement.routine
      prepare_readouts
      render :index
    else
      render :edit
    end
  end

  def toggle_exposure
    @routine.readout_exposures.toggle!(@quantity)
    prepare_readouts
  end

  private

  def measurement_params
    params.require(:measurement).permit(
      :notes,
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

  def prepare_readouts
    @quantities = @routine.quantities.includes(:formula)

    @measurements, @filter_q = @routine.measurements.includes(:routine, :source)
      .filter(session[:m_filters], @quantities)

    # Keep only non-nil readouts and their ancestors
    @measurements.each do |measurement, readouts|
      ancestors = {}
      readouts.keys.sort_by(&:depth).reverse_each do |q|
        readouts[q] || ancestors[q] ? ancestors[q.parent] = true : readouts.delete(q)
      end
    end
  end
end
