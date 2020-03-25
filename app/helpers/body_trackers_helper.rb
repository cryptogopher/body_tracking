module BodyTrackersHelper
  def format_value(value)
    amount, unitname = value
    case
    when amount.nil?
      '-'
    when amount.nan?
      '?'
    else
      "#{amount} [#{unitname || '-'}]"
    end
  end

  def unit_options
    @project.units.map do |u|
      [u.shortname, u.id]
    end
  end
end
