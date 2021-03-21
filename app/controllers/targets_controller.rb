class TargetsController < ApplicationController
  layout 'body_tracking', except: :subthresholds
  menu_item :body_trackers
  helper :body_trackers

  include Concerns::Finders

  before_action :find_binding_goal_by_project_id, only: [:edit]
  before_action :find_project_by_project_id, only: [:subthresholds]
  before_action :find_quantity_by_quantity_id, only: [:toggle_exposure]
  before_action :find_goal_by_goal_id, only: [:index, :new, :create]
  before_action :find_goal, only: [:toggle_exposure]
  before_action :authorize
  #before_action :set_view_params

  def index
    prepare_targets
  end

  def new
    target = @goal.targets.new
    @targets = [target]
    @effective_from = target.effective_from
  end

  def create
    @effective_from = params[:goal].delete(:effective_from)
    params[:goal][:targets_attributes].each { |ta| ta[:effective_from] = @effective_from }

    if @goal.update(targets_params)
      flash.now[:notice] = 'Created new target(s)'
      prepare_targets
    else
      @targets = @goal.targets.select(&:changed_for_autosave?)
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
    @goal.exposures.toggle!(@quantity)
    prepare_targets
  end

  def subthresholds
    @target = @project.goals.binding.targets.new
    quantity = @project.quantities.target.find_by(id: params[:quantity_id])
    if quantity.nil?
      @last_quantity = @project.quantities.target.find(params[:parent_id])
      @target.thresholds.clear
    else
      @last_quantity = quantity
      @target.thresholds.first.quantity = quantity
    end
  end

  private

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
    @goal.targets.includes(:item, thresholds: [:quantity]).reject(&:new_record?)
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
