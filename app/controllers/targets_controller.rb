class TargetsController < ApplicationController
  layout 'body_tracking'
  menu_item :body_trackers
  helper :body_trackers

  include Concerns::Finders

  before_action :find_binding_goal_by_project_id, only: [:index, :new, :edit]
  before_action :find_project_by_project_id, only: [:create]
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
    target.arity.times { target.thresholds.new }
    @targets = [target]
  end

  def create
    @goal = @project.goals.find(params[:goal_id]) if params[:goal_id].present?
    @goal ||= @project.goals.new
    @goal.attributes = goal_params unless @goal.is_binding?

    @targets = @goal.targets.build(targets_params[:targets]) do |target|
      target.effective_from = params[:target][:effective_from]
    end
    if @goal.target_exposures.empty?
      @goal.quantities << @targets.map { |t| t.thresholds.first.quantity }.first(6)
    end

    # :save only after build, to re-display values in case records are invalid
    if @goal.save && Target.transaction { @targets.all?(&:save) }
      flash.now[:notice] = 'Created new target(s)'
      # create view should only refresh targets belonging to @goal
      # e.g. by rendering to div#goal-id-targets
      prepare_targets
    else
      @targets.each do |target|
        (target.thresholds.length...target.arity).each { target.thresholds.new }
        target.thresholds[target.arity..-1].map(&:destroy)
      end
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

  private

  def goal_params
    params.require(:goal).permit(:name, :description)
  end

  def targets_params
    params.require(:target).permit(
      targets: [
        :id,
        :condition,
        :scope,
        thresholds_attributes: [
          :id,
          :quantity_id,
          :value,
          :unit_id
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
