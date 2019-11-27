module QuantitiesHelper
  def domain_options
    translations = t('quantities.form.domains')
    Quantity.domains.map do |k,v|
      [translations[k.to_sym], k]
    end
  end

  def domain_options_tag(selected)
    options_for_select(domain_options, selected)
  end

  def parent_options(domain)
    options = nested_set_options(@project.quantities.send(domain), @quantity) do |i|
      raw("#{'&ensp;' * i.level}#{i.name}")
    end
  end
end
