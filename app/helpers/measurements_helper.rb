module MeasurementsHelper
  def readout_markup(quantity, readout)
    content = "#{'&emsp;'*quantity.depth}#{quantity.name} #{format_amount(readout)}"
    classes = 'bolded' if @routine.quantities.include?(quantity)
    content_tag(:span, content, {class: classes}, false)
  end

  def action_links(m)
    link_to(l(:button_retake), retake_measurement_path(m, @view_params),
            {remote: true, class: "icon icon-reload"}) +
    link_to(l(:button_edit), edit_measurement_path(m, @view_params),
            {remote: true, class: "icon icon-edit"}) +
    delete_link(measurement_path(m), {remote: true, data: {}})
  end
end
