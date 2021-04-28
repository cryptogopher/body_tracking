class TargetsController < ApplicationController
  layout 'body_tracking', except: :subthresholds
  menu_item :body_trackers
  helper :body_trackers

  include Concerns::Finders

  before_action :find_goal_by_goal_id,
    only: [:index, :new, :create, :edit, :update, :destroy, :toggle_exposure]
  before_action :find_quantity_by_quantity_id, only: [:toggle_exposure, :subthresholds]
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
      count = @goal.targets.target.length
      if count > 0
        flash.now[:notice] = t('.success', count: count)
        prepare_targets
      else
        flash.now[:warning] = t('.success', count: 0)
        @targets = [@goal.targets.new]
        render :new
      end
    else
      @targets = @goal.targets.select(&:changed_for_autosave?)
        .each { |t| t.thresholds.new unless t.thresholds.present? }
      render :new
    end
  end

  def edit
    @targets = @goal.targets.joins(:quantity).where(effective_from: params[:date])
      .order('quantities.lft' => :asc).to_a
    @effective_from = @targets.first&.effective_from
  end

  def update
    # TODO: DRY same code with #create
    @effective_from = params[:goal].delete(:effective_from)
    params[:goal][:targets_attributes].each { |ta| ta[:effective_from] = @effective_from }

    if @goal.update(targets_params)
      count = @goal.targets.target.count { |t| t.previous_changes.present? }
      flash.now[:notice] = t('.success', count: count)
      prepare_targets
      render :index
    else
      @targets = @goal.targets.where(id: targets_params[:targets_attributes].pluck(:id))
      @targets += @goal.targets.target.select(&:changed_for_autosave?)
        .each { |t| t.thresholds.new unless t.thresholds.present? }
      render :edit
    end
  end

  def destroy
    @effective_from = params[:date]
    @targets = @goal.targets.where(effective_from: @effective_from)
    count = @targets.destroy_all.length
    if @targets.all?(&:destroyed?)
      flash.now[:notice] = t('.success', count: count)
    else
      flash.now[:error] = t('.failure')
    end
  end

  def reapply
  end

  def toggle_exposure
    @goal.exposures.toggle!(@quantity)
    prepare_targets
  end

  def subthresholds
    @quantities = @quantity.children
  end

  private

  def targets_params
    params.require(:goal).permit(
      targets_attributes:
        [
          :id,
          :quantity_id,
          :scope,
          :effective_from,
          :_destroy,
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
