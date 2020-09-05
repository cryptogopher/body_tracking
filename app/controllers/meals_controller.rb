class MealsController < ApplicationController
  layout 'body_tracking'
  menu_item :body_trackers
  helper :body_trackers

  include Concerns::Finders

  before_action :find_project_by_project_id, only: [:index, :new, :create]
  before_action :find_quantity_by_quantity_id, only: [:toggle_exposure]
  before_action :find_meal, only: [:edit, :update, :destroy, :edit_notes, :update_notes,
                                   :toggle_eaten]
  before_action :find_ingredient, only: [:adjust]
  before_action :authorize

  def index
    prepare_meals
  end

  def new
    @meal = @project.meals.new
    @meal.ingredients.new
  end

  def create
    @meal = @project.meals.new(meal_params)
    if @meal.save
      flash.now[:notice] = 'Created new meal'
      prepare_meals
    else
      @meal.ingredients.new if @meal.ingredients.empty?
      render :new
    end
  end

  def edit
  end

  def update
    if @meal.update(meal_params)
      flash.now[:notice] = 'Updated meal'
      prepare_meals
      render :index
    else
      render :edit
    end
  end

  def destroy
    flash.now[:notice] = 'Deleted meal' if @meal.destroy
  end

  def edit_notes
  end

  def update_notes
    @meal.update(params.require(:meal).permit(:notes))
  end

  def toggle_eaten
    @meal.toggle_eaten!
    prepare_meals
  end

  def toggle_exposure
    @project.meal_exposures.toggle!(@quantity)
    prepare_meals
  end

  def adjust
    amount = params[:adjustment].to_i
    @ingredient.amount += amount if @ingredient.amount > -amount
    @ingredient.save

    prepare_meals
    @meal = @ingredient.composition
    @date = @meal.display_date
    @meal_index = @meals_by_date[@date].index(@meal)
  end

  private

  def meal_params
    params.require(:meal).permit(
      :notes,
      ingredients_attributes:
      [
        :id,
        :food_id,
        :amount,
        :_destroy
      ]
    )
  end

  def prepare_meals
    @meals_by_date = @project.meals.reject(&:new_record?)
      .sort_by { |m| m.eaten_at || m.created_at }.group_by(&:display_date)

    return if @meals_by_date.empty?

    @quantities = @project.meal_quantities.includes(:formula)
    @ingredients = @project.meal_ingredients.compute_quantities(@quantities) do |q, items|
      Hash.new { |h,k| k.composition } if q == Meal
    end

    @amount_mfu_unit = @ingredients
      .each_with_object(Hash.new(0)) { |(i, qv), h| h[i.food.ref_unit] += 1 }
      .max_by(&:last).first

    @ingredient_summary = Hash.new { |h,k| h[k] = Hash.new(BigDecimal(0)) }
    @quantities.each do |q|
      @ingredient_summary[:mfu_unit][q] = @ingredients
        .each_with_object(Hash.new(0)) { |(i, qv), h| h[qv[q].last] += 1 if qv[q] }
        .max_by(&:last).try(&:first)

      max_value = @ingredients.map { |i, qv| qv[q].try(&:first) || BigDecimal(0) }.max
      @ingredient_summary[:precision][q] = [3 - max_value.exponent, 0].max
    end

    # TODO: summing up ingredients should take units into account
    @ingredients.each do |i, qv|
      meal = i.composition
      qv.compact.each do |q, (a, u)|
        @ingredient_summary[meal][q] += a
        @ingredient_summary[meal.display_date][q] += a
      end
    end
  end
end
