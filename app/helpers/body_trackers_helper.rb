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
    enabled = enabled.map { |q| [q.name, q.id] }
    enabled_ids = enabled.map(&:last)

    options = [[t('body_trackers.helpers.exposures_available'), 0]]
    options += nested_set_options(@project.quantities.send(domain)) do |q|
      raw("#{'&ensp;' * q.level}#{q.name}")
    end
    options.collect! { |name, id| [name, enabled_ids.include?(id) ? 0 : id] }

    options = [[t('body_trackers.helpers.exposures_enabled'), 0]] + enabled + options
    options_for_select(options, disabled: 0)
  end

  def unit_options
    @project.units.map do |u|
      [u.shortname, u.id]
    end
  end
end
