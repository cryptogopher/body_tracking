class QuantitiesController < ApplicationController
  before_action :find_project_by_project_id, only: [:index, :create]
  before_action :find_quantity, only: [:destroy, :toggle]
  before_action :authorize

  def index
    @quantity = @project.quantities.new
    @quantities = @project.quantities
  end

  def create
    @quantity = @project.quantities.new(quantity_params)
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

  def toggle
    @quantity.update(primary: !@quantity.primary)
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
