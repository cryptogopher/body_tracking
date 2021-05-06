module MeasurementsHelper
  def format_datetime(m)
    m.taken_at
      .strftime("%F <small>%R&emsp;(~#{time_ago_in_words(m.taken_at)} ago)</small>")
      .html_safe
  end

  def action_links(m)
    link_to(l(:button_retake), retake_measurement_path(m, @view_params),
            {remote: true, class: "icon icon-reload"}) +
    link_to(l(:button_edit), edit_measurement_path(m, @view_params),
            {remote: true, class: "icon icon-edit"}) +
    delete_link(measurement_path(m), {remote: true, data: {}})
  end
end
