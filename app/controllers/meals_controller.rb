class MealsController < ApplicationController
  layout 'body_tracking'
  menu_item :body_trackers
  helper :body_trackers

  include Concerns::Finders

  before_action :find_project_by_project_id, only: [:index, :new, :create]
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
