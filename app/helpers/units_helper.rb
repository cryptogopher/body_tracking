module UnitsHelper
  def group_options
    translations = t('.groups')
    Unit.groups.map { |k,v| [translations[k.to_sym], k] }
  end
end
