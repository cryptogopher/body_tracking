class IngredientsController < ApplicationController
  before_action :find_project_by_project_id, only: [:index, :create]
  before_action :find_ingredient, only: [:destroy]
  before_action :authorize

  def index
    @ingredient = Ingredient.new(project: @project)
    # passing attr for after_initialize
    @ingredient.nutrients.new(ingredient: @ingredient)
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
    # FIXME: don't destroy if any meal depend on ingredient
    if @ingredient.destroy
      flash[:notice] = 'Deleted ingredient'
    end
    redirect_to project_ingredients_url(@project)
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

  # :find_* methods are called before :authorize,
  # @project is required for :authorize to succeed
  def find_ingredient
    @ingredient = Ingredient.find(params[:id])
    @project = @ingredient.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
