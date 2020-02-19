class QuantitiesController < ApplicationController
  menu_item :body_trackers

  before_action :init_session_filters
  before_action :find_project_by_project_id, only: [:index, :new, :create, :filter, :parents]
  before_action :find_quantity, only: [:edit, :update, :destroy, :move]
  before_action :authorize

  def index
    prepare_quantities
  end

  def new
    @quantity = @project.quantities.new
    @quantity.domain = Quantity.domains[session[:q_filters][:domain]] || @quantity.domain
    @quantity.build_formula
  end

  def create
    @quantity = @project.quantities.new(quantity_params)
    if @quantity.save
      flash[:notice] = 'Created new quantity'
      prepare_quantities
    else
      render :new
    end
  end

  def edit
    @quantity.build_formula unless @quantity.formula
  end

  def update
    if @quantity.update(quantity_params)
      flash[:notice] = 'Updated quantity'
      prepare_quantities
      render :index
    else
      render :edit
    end
  end

  def destroy
    @quantity_tree = @quantity.self_and_descendants.load
    if @quantity.destroy
      flash[:notice] = 'Deleted quantity'
    end
  end

  def filter
    session[:q_filters] = params[:filters]
    prepare_quantities
    render :index
  end

  def parents
    @form = params[:form]
    @domain = params[:quantity][:domain]
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
    params.require(:quantity).permit(
      :domain,
      :parent_id,
      :name,
      :description,
      formula_attributes:
      [
        :code,
        :zero_nil
      ]
    )
  end

  def prepare_quantities
    @quantities = @project.quantities.filter(@project, session[:q_filters])
      .includes(:column_views, :formula)
  end
end
