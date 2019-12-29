module BodyTrackersHelper
  def format_value(value)
    amount, unitname = value
    amount.nil? ? '-' : "#{amount} [#{unitname || '-'}]"
  end
end
