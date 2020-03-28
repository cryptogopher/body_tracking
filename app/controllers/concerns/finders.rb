module Concerns::Finders
  private

  def find_ingredient
    @ingredient = Ingredient.find(params[:id])
    @project = @ingredient.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_measurement
    @measurement = Measurement.find(params[:id])
    @project = @measurement.routine.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_measurement_routine
    @routine = MeasurementRoutine.find(params[:id])
    @project = @routine.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_quantity(id = :id)
    @quantity = Quantity.find(params[id])
    @project = @quantity.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_quantity_by_quantity_id
    find_quantity(:quantity_id)
  end

  def find_unit
    @unit = Unit.find(params[:id])
    @project = @unit.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
