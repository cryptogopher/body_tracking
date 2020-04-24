module BodyTrackersHelper
  def format_value(value)
    amount, unit = value
    case
    when amount.nil?
      '-'
    when amount.nan?
      '?'
    else
      "#{amount} [#{unit.shortname || '-'}]"
    end
  end

  def format_time(t)
    t.strftime("%R") if t
  end

  def unit_options
    @project.units.map do |u|
      [u.shortname, u.id]
    end
  end
end
