module MeasurementsHelper
  def format_datetime(m)
    m.taken_at.getlocal.strftime("%F <small>%R</small>").html_safe
  end

  def format_time(m)
    m.taken_at.getlocal.strftime("%R")
  end

  def format_value(value)
    amount, unitname = value
    amount.nil? ? '-' : "#{amount} [#{unitname || '-'}]"
  end

  def quantity_toggle_options
    disabled = []
    options = nested_set_options(@project.quantities.measurement) do |q|
      disabled << q.id if q.primary
      raw("#{'&ensp;' * q.level}#{q.name}")
    end
    options_for_select(options, disabled: disabled)
  end

  def quantity_options
    nested_set_options(@project.quantities.measurement) do |q|
      raw("#{'&ensp;' * q.level}#{q.name}")
    end
  end

  def unit_options
    @project.units.map do |u|
      [u.shortname, u.id]
    end
  end

  def source_options
    @project.sources.map do |s|
      [s.name, s.id]
    end
  end
end
