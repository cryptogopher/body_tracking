class IngredientsController < ApplicationController
  before_action :find_project_by_project_id, only: [:index, :create]
  before_action :authorize

  def index
    @ingredient = Ingredient.new
    @ingredient.nutrients.build
    @ingredients = @project.ingredients
  end

  def create
  end

  def destroy
  end
end
