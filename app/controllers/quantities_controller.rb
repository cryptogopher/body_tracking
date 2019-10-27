class QuantitiesController < ApplicationController
  before_action :find_project_by_project_id, only: [:index, :create]
  before_action :find_quantity, only: [:destroy, :toggle, :up, :down, :left, :right]
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
    @quantities = @project.quantities
  end

  def up
    @quantity.move_left if @quantity.left_sibling.present?
    @quantities = @project.quantities
    render :toggle
  end

  def down
    @quantity.move_right if @quantity.right_sibling.present?
    @quantities = @project.quantities
    render :toggle
  end

  def left
    @quantity.move_to_right_of(@quantity.parent) if @quantity.parent.present?
    @quantities = @project.quantities
    render :toggle
  end

  def right
    @quantity.move_to_child_of(@quantity.left_sibling) if @quantity.left_sibling.present?
    @quantities = @project.quantities
    render :toggle
  end

  private

  def quantity_params
    params.require(:quantity).permit(
      :name,
      :description,
      :domain,
      :parent_id,
      :primary
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
