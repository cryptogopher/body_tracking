module BodyTrackersHelper
  def format_value(value, precision=2, mfu_unit=nil)
    amount, unit = value
    case
    when amount.nil?
      '-'
    when amount.nan?
      '?'
    else
      a = amount.round(precision)
      a_desc = a.nonzero? ? "%.#{precision}f" % a : '-'
      u_desc = unit && " [#{unit.shortname}]" || ' [-]' if unit != mfu_unit && a.nonzero?
      "#{a_desc}#{u_desc}"
    end
  end

  def format_time(t)
    t.strftime("%R") if t
  end

  def toggle_exposure_options(enabled, domain)
    disabled = []
    enabled = enabled.to_a
    options = nested_set_options(@project.quantities.send(domain)) do |q|
      disabled << q.id if enabled.include?(q)
      raw("#{'&ensp;' * q.level}#{q.name}")
    end
    options_for_select(options, disabled: disabled)
  end

  def unit_options
    @project.units.map do |u|
      [u.shortname, u.id]
    end
  end
end
