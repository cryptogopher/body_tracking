class QuantitiesController < ApplicationController
  before_action :init_session_filters
  before_action :find_project_by_project_id, only: [:index, :create, :filter]
  before_action :find_quantity, only: [:destroy, :toggle, :up, :down, :left, :right]
  before_action :authorize

  def index
    @quantity = @project.quantities.new
    @quantity.domain = Quantity.domains[session[:q_filters][:domain]]
    prepare_quantities
  end

  def create
    @quantity = @project.quantities.new(quantity_params)
    if @quantity.save
      flash[:notice] = 'Created new quantity'
      redirect_to project_quantities_url(@project)
    else
      prepare_quantities
      render :index
    end
  end

  def destroy
    if @quantity.destroy
      flash[:notice] = 'Deleted quantity'
    end
    prepare_quantities
    render :toggle
  end

  def toggle
    @quantity.toggle_primary!
    prepare_quantities
  end

  def filter
    session[:q_filters] = params[:filters]
    prepare_quantities
    render :toggle
  end

  def up
    @quantity.move_left if @quantity.left_sibling.present?
    prepare_quantities
    render :toggle
  end

  def down
    @quantity.move_right if @quantity.right_sibling.present?
    prepare_quantities
    render :toggle
  end

  def left
    @quantity.move_to_right_of(@quantity.parent) if @quantity.parent.present?
    prepare_quantities
    render :toggle
  end

  def right
    @quantity.move_to_child_of(@quantity.left_sibling) if @quantity.left_sibling.present?
    prepare_quantities
    render :toggle
  end

  private

  def init_session_filters
    session[:q_filters] ||= {}
  end

  def quantity_params
    params[:quantity].delete(:formula) if params[:quantity][:formula].blank?
    params.require(:quantity).permit(
      :domain,
      :parent_id,
      :name,
      :description,
      :formula,
      :primary
    )
  end

  def prepare_quantities
    @quantities = @project.quantities.filter(@project, session[:q_filters])
  end
end
