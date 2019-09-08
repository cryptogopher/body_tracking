class QuantitiesController < ApplicationController
  before_action :find_project_by_project_id, only: [:index, :create]
  before_action :find_quantity, only: [:destroy]
  before_action :authorize

  def index
    @quantity = Quantity.new
    @quantities = @project.quantities
  end

  def create
    @quantity = Quantity.new(quantity_params.update(project: @project))
    if @quantity.save
      flash[:notice] = 'Created new quantity'
      redirect_to project_quantities_url(@project)
    else
      @quantities = @project.quantities
      render :index
    end
  end

  def destroy
    if @quantity.destroy
      flash[:notice] = 'Deleted quantity'
    end
    redirect_to project_quantities_url(@project)
  end

  private

  def quantity_params
    params.require(:quantity).permit(
      :name,
      :description,
      :domain,
      :parent_id
    )
  end

  # :find_* methods are called before :authorize,
  # @project is required for :authorize to succeed
  def find_quantity
    @quantity = Quantity.find(params[:id])
    @project = @quantity.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
