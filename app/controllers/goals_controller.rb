class GoalsController < ApplicationController
  layout 'body_tracking', except: :subthresholds
  menu_item :body_trackers
  helper :body_trackers

  include Concerns::Finders

  before_action :find_project_by_project_id, only: [:index, :new, :create]
  before_action :find_goal, only: [:edit, :update, :destroy]
  before_action :authorize

  def index
    @goals = @project.goals
  end

  def new
    @goal = @project.goals.new
    @targets = @goal.targets
  end

  def create
    @goal = @project.goals.new(goal_params)
    if @goal.save
      flash.now[:notice] = 'Created new goal'
      @goals = @project.goals
    else
      @targets = @goal.targets
      render :new
    end
  end

  def edit
  end

  def update
    if @goal.update(params.require(:goal).permit(:name, :description))
      flash.now[:notice] = 'Updated goal'
      @goals = @project.goals
    else
      render :new
    end
  end

  def destroy
    # TODO
  end

  private

  def goal_params
    params.require(:goal).permit(
      :name,
      :description,
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
end
