module UnitsHelper
  def type_options
    translations = t('.types')
    Unit.types.map { |k,v| [translations[k.to_sym], k] }
  end
end
