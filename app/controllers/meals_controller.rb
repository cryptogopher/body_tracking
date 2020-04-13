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

  private

  def prepare_meals
    @meals = @project.meals.includes(:ingredients)
  end
end
