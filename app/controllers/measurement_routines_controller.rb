class MeasurementRoutinesController < ApplicationController
  include Concerns::Finders

  before_action :find_measurement_routine, only: [:show, :edit]
  before_action :authorize

  def show
  end

  def edit
  end
end
