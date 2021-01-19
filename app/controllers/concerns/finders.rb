module Concerns::Finders
  private

  def find_goal(id = params[:id])
    @goal = Goal.find(id)
    @project = @goal.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_binding_goal_by_project_id
    @project = Project.find(params[:project_id])
    @goal = @project.goals.binding
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_meal
    @meal = Meal.find(params[:id])
    @project = @meal.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_ingredient
    @ingredient = Ingredient.find(params[:id])
    @project = @ingredient.composition.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_food
    @food = Food.find(params[:id])
    @project = @food.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_measurement
    @measurement = Measurement.find(params[:id])
    # DON'T set @routine here: @routine is a context for :readouts view (set
    # elsewhere), not a # @measurement.routine
    @project = @measurement.routine.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_measurement_routine(id = params[:id])
    @routine = MeasurementRoutine.find(id)
    @project = @routine.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_measurement_routine_by_measurement_routine_id
    find_measurement_routine(params[:measurement_routine_id])
  end

  def find_quantity(id = params[:id])
    @quantity = Quantity.find(id)
    @project = @quantity.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_quantity_by_quantity_id
    find_quantity(params[:quantity_id])
  end

  def find_unit
    @unit = Unit.find(params[:id])
    @project = @unit.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
