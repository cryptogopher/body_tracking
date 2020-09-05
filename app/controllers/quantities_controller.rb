class QuantitiesController < ApplicationController
  layout 'body_tracking'
  menu_item :body_trackers
  helper :body_trackers

  include Concerns::Finders

  before_action :init_session_filters
  before_action :find_project_by_project_id, only: [:index, :new, :create, :filter, :parents]
  before_action :find_quantity, only: [:edit, :update, :destroy, :move,
                                       :new_child, :create_child]
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
      flash.now[:notice] = 'Created new quantity'
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
      flash.now[:notice] = 'Updated quantity'
      prepare_quantities
      render :index
    else
      render :edit
    end
  end

  def destroy
    @quantity_tree = @quantity.self_and_descendants.load
    if @quantity.destroy
      flash.now[:notice] = 'Deleted quantity'
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
    render layout: false
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

  def new_child
    @parent_quantity = @quantity
    @quantity = @project.quantities.new
    @quantity.domain = @parent_quantity.domain
    @quantity.parent = @parent_quantity
    @quantity.build_formula
  end

  def create_child
    @quantity = @project.quantities.new(quantity_params)
    unless @quantity.save
      @parent_quantity = @quantity.parent
      render :new_child
    end
    flash.now[:notice] = 'Created new quantity'
    prepare_quantities
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
        :id,
        :code,
        :zero_nil,
        :unit_id,
        :_destroy
      ]
    )
  end

  def prepare_quantities
    @quantities = @project.quantities.filter(@project, session[:q_filters])
      .includes(:exposures, :formula, :parent)
  end
end
