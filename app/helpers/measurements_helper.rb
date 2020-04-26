module MeasurementsHelper
  def format_datetime(m)
    m.taken_at
      .strftime("%F <small>%R&emsp;(~#{time_ago_in_words(m.taken_at)} ago)</small>")
      .html_safe
  end

  def quantity_options
    nested_set_options(@project.quantities.measurement) do |q|
      raw("#{'&ensp;' * q.level}#{q.name}")
    end
  end

  def source_options
    @project.sources.map do |s|
      [s.name, s.id]
    end
  end

  def action_links(m)
    link_to(l(:button_retake), retake_measurement_path(m, @view_params),
            {remote: true, class: "icon icon-reload"}) +
    link_to(l(:button_edit), edit_measurement_path(m, @view_params),
            {remote: true, class: "icon icon-edit"}) +
    delete_link(measurement_path(m), {remote: true, data: {}})
  end
end
