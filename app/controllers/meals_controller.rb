class MealsController < ApplicationController
  layout 'body_tracking'
  menu_item :body_trackers
  helper :body_trackers

  include Concerns::Finders

  before_action :find_project_by_project_id, only: [:index, :new, :create]
  before_action :find_meal, only: [:edit, :update, :destroy]
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

  def destroy
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
    @meals = @project.meals.includes(:foods)
  end
end
