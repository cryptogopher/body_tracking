class TargetsController < ApplicationController
  layout 'body_tracking'
  menu_item :body_trackers
  helper :body_trackers

  include Concerns::Finders

  before_action :find_project_by_project_id, only: [:index, :new, :create]

  def index
    prepare_targets
  end

  def new
    target = (@goal || @project.goals.binding).targets.new
    target.arity.times { target.thresholds.new }
    @targets = [target]
  end

  def create
    goal = @project.goals.find_by(id: params[:goal][:id]) || @project.goals.build(goal_params)
    @targets = goal.targets.build(targets_params[:targets]) do |target|
      target.effective_from = params[:target][:effective_from]
    end

    # :save only after build, to re-display values in case records are invalid
    if goal.save && Target.transaction { @targets.all?(&:save) }
      flash[:notice] = 'Created new target(s)'
      prepare_targets
    else
      @targets.each do |target|
        (target.thresholds.length...target.arity).each { target.thresholds.new }
        target.thresholds[target.arity..-1].map(&:destroy)
      end
      render :new
    end
  end

  private

  def goal_params
    params.require(:goal).permit(:id, :name, :description)
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
    @targets = @project.targets.includes(:item, :thresholds)
  end
end
