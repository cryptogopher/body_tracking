module QuantitiesHelper
  def domain_options
    translations = t('.domains')
    Quantity.domains.map do |k,v|
      [translations[k.to_sym], k]
    end
  end
end
