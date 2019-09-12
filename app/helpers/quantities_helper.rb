module QuantitiesHelper
  def domain_options
    translations = t('.domains')
    Quantity.domains.map do |k,v|
      [translations[k.to_sym], k]
    end
  end

  def parent_options(domain)
    options = nested_set_options(@quantities.send(domain), @quantity) do |i|
      raw("#{'&ensp;' * i.level}#{i.name}")
    end
    options.unshift([t('.null_parent'), nil])
  end
end
