class TargetsController < ApplicationController
  layout 'body_tracking'
  menu_item :body_trackers
  helper :body_trackers

  include Concerns::Finders

  before_action :find_project_by_project_id, only: [:index]

  def index
    prepare_targets
  end

  def new
    @target = @project.targets.new
    @target.arity.times { @target.thresholds.new }
  end

  private

  def prepare_targets
    @targets = @project.targets.includes(:item, :thresholds)
  end
end
