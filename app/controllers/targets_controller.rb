class TargetsController < ApplicationController
  layout 'body_tracking', except: :subthresholds
  menu_item :body_trackers
  helper :body_trackers

  include Concerns::Finders

  before_action :find_binding_goal_by_project_id, only: [:index, :new, :edit]
  before_action :find_project_by_project_id, only: [:create, :subthresholds]
  before_action :find_quantity_by_quantity_id, only: [:toggle_exposure]
  #,  if: ->{ params[:project_id].present? }
  #before_action :find_goal, only: [:index, :new],
  #  unless: -> { @goal }
  before_action :find_goal, only: [:toggle_exposure]
  before_action :authorize
  #before_action :set_view_params

  def index
    prepare_targets
  end

  def new
    target = @goal.targets.new
    target.thresholds.new(quantity: Quantity.target.roots.last)
    @targets = [target]
    @effective_from = target.effective_from
  end

  def create
    @goal = @project.goals.find_by(id: params[:goal][:id]) || @project.goals.new
    @goal.attributes = goal_params
    @targets = @goal.targets.build(targets_params[:targets_attributes]) do |target|
      target.effective_from = params[:target][:effective_from]
    end

    if @goal.target_exposures.empty?
      @goal.quantities << @targets.map(&:quantity)[0..5]
    end

    # :save only after build, to re-display values in case records are invalid
    if @goal.save
      flash.now[:notice] = 'Created new target(s)'
      # create view should only refresh targets belonging to @goal
      # e.g. by rendering to div#goal-id-targets
      prepare_targets
    else
      @targets.each { |t| t.thresholds.new unless t.thresholds.present? }
      render :new
    end
  end

  def edit
    @targets = @goal.targets.where(effective_from: params[:date]).to_a
    @effective_from = @targets.first&.effective_from
  end

  def update
    # TODO: DRY same code with #create
    @goal = @project.goals.find(params[:goal_id]) if params[:goal_id].present?
    @goal ||= @project.goals.new
    @goal.attributes = goal_params unless @goal.is_binding?
  end

  def destroy
  end

  def reapply
  end

  def toggle_exposure
    @goal.target_exposures.toggle!(@quantity)
    prepare_targets
  end

  def subthresholds
    @target = @project.goals.binding.targets.new
    quantity = @project.quantities.target.find_by(id: params['quantity_id'])
    if quantity.nil?
      @last_quantity = @project.quantities.target.find(params[:parent_id])
    else
      @last_quantity = quantity
      @target.thresholds.new(quantity: quantity)
    end
  end

  private

  def goal_params
    params.require(:goal).permit(
      :name,
      :description
    )
  end

  def targets_params
    params.require(:goal).permit(
      targets_attributes:
        [
          :id,
          :quantity_id,
          :scope,
          :destroy,
          thresholds_attributes: [
            :id,
            :quantity_id,
            :value,
            :unit_id,
            :_destroy
          ]
        ]
    )
  end

  def prepare_targets
    @quantities = @goal.quantities.includes(:formula)

    @targets_by_date = Hash.new { |h,k| h[k] = {} }
    @project.targets.includes(:item, thresholds: [:quantity]).reject(&:new_record?)
      .each { |t| @targets_by_date[t.effective_from][t.thresholds.first.quantity] = t }
  end

  def set_view_params
    @view_params = case params[:view]
                   when 'by_effective_from'
                     {view: :by_effective_from, effective_from: @effective_from}
                   when 'by_item_quantity'
                     {view: :by_item_quantity, item: nil, quantity: @quantity}
                   else
                     {view: :by_scope, scope: :all}
                   end
    #@view_params[:goal_id] = @goal.id if @goal
  end
end
