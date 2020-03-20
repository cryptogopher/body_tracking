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
end
