class BodyTrackingPluginController < ApplicationController
  menu_item :body_trackers
  layout 'body_tracking'

  private

  def find_quantity(id = :id)
    @quantity = Quantity.find(params[id])
    @project = @quantity.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_quantity_by_quantity_id
    find_quantity(:quantity_id)
  end
end
