class MealsController < ApplicationController
  layout 'body_tracking'
  menu_item :body_trackers
  helper :body_trackers

  include Concerns::Finders

  before_action :find_project_by_project_id, only: [:index, :new, :create]
  before_action :find_quantity_by_quantity_id, only: [:toggle_exposure]
  before_action :find_meal, only: [:edit, :update, :destroy, :edit_notes, :update_notes,
                                   :toggle_eaten]
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
      flash[:notice] = 'Created new meal'
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
      flash[:notice] = 'Updated meal'
      prepare_meals
      render :index
    else
      render :edit
    end
  end

  def destroy
    flash[:notice] = 'Deleted meal' if @meal.destroy
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
    @quantities = @project.meal_quantities.includes(:formula)
    foods = @project.meal_foods.compute_quantities(@quantities)
    ingredients = @project.meal_ingredients

    @nutrients = {}
    ingredients.each do |i|
      @nutrients[i] = foods[i.food].map do |q, v|
        [q, v && [v[0]*i.amount/i.food.ref_amount, v[1]]]
      end.to_h
    end

    @meals_by_date = ingredients.group_by { |i| i.composition }.reject { |m,*| m.new_record? }
      .sort_by { |m,*| m.eaten_at || m.created_at }
      .group_by { |m,*| m.eaten_at ? m.eaten_at.to_date : Date.current }
  end
end
