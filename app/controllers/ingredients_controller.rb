class IngredientsController < ApplicationController
  before_action :find_project_by_project_id, only: [:index, :create]
  before_action :authorize

  def index
    @ingredient = Ingredient.new
    @ingredient.nutrients.build
    @ingredients = @project.ingredients
  end

  def create
    @ingredient = Ingredient.new(ingredient_params.update(project: @project))
    if @ingredient.save
      flash[:notice] = 'Created new ingredient'
      redirect_to project_ingredients_url(@project)
    else
      @ingredients = @project.ingredients
      render :index
    end
  end

  def destroy
  end

  private

  def ingredient_params
    params.require(:ingredient).permit(
      :name,
      :ref_amount,
      :ref_unit_id,
      :group,
      nutrients_attributes:
      [
        :id,
        :quantity_id,
        :amount,
        :unit_id,
        :_destroy
      ]
    )
  end
end
