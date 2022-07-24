module MeasurementsHelper
  def action_links(m)
    link_to(l(:button_retake), retake_measurement_path(m),
            {remote: true, class: "icon icon-reload"}) +
    link_to(l(:button_edit), edit_measurement_path(m),
            {remote: true, class: "icon icon-edit"}) +
    delete_link(measurement_path(m), {remote: true, data: {}})
  end
end
