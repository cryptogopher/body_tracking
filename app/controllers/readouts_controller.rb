class ReadoutsController < ApplicationController
  layout 'body_tracking'
  menu_item :body_trackers
  helper :body_trackers
  helper :measurements

  include Concerns::Finders

  before_action :find_measurement_routine_by_measurement_routine_id,
    only: [:index, :toggle_exposure]
  before_action :find_quantity_by_quantity_id, only: [:toggle_exposure]
  before_action :authorize

  def index
    prepare_readouts
  end

  def toggle_exposure
    @routine.readout_exposures.toggle!(@quantity)
    prepare_readouts
  end

  private

  def prepare_readouts
    @quantities = @routine.quantities.includes(:formula)

    @measurements, @filter_q = @routine.measurements.includes(:routine, :source)
      .filter(session[:m_filters], @quantities)
  end
end
