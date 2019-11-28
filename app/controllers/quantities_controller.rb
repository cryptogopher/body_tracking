class QuantitiesController < ApplicationController
  menu_item :body_trackers

  before_action :init_session_filters
  before_action :find_project_by_project_id, only: [:index, :parents, :create, :filter]
  before_action :find_quantity, only: [:edit, :update, :destroy, :toggle, :move]
  before_action :authorize

  def index
    @quantity = @project.quantities.new
    @quantity.domain = Quantity.domains[session[:q_filters][:domain]] || @quantity.domain
    prepare_quantities
  end

  def parents
    @form = params[:form]
    @domain = params[:quantity][:domain]
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

  def filter
    session[:q_filters] = params[:filters]
    prepare_quantities
    render :index
  end

  def edit
    prepare_quantities
    render :index
  end

  def update
    if @quantity.update(quantity_params)
      flash[:notice] = 'Updated quantity'
    end
    prepare_quantities
    render :index
  end

  def destroy
    if @quantity.destroy
      flash[:notice] = 'Deleted quantity'
    end
    prepare_quantities
    render :index
  end

  def toggle
    @quantity.toggle_primary!
    prepare_quantities
  end

  def move
    direction = params[:direction].to_sym
    case direction
    when :up
      @quantity.move_left
    when :down
      @quantity.move_right
    when :left
      @quantity.move_to_right_of(@quantity.parent)
    when :right
      @quantity.move_to_child_of(@quantity.left_sibling)
    end if @quantity.movable?(direction)

    prepare_quantities
    render :index
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
