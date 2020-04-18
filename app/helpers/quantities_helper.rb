module QuantitiesHelper
  def order_links(q)
    [:up, :down, :left, :right].map do |direction|
      if q.movable?(direction)
        link_to '', move_quantity_path(q, direction),
          {remote: true, method: :post, class: "icon icon-move icon-move-#{direction}"}
      else
        link_to '', '', {class: "icon", style: "visibility: hidden;"}
      end
    end.reduce(:+)
  end

  def action_links(q)
    link_to(l(:button_child), new_child_quantity_path(q),
            {remote: true, class: "icon icon-add"}) +
    link_to(l(:button_edit), edit_quantity_path(q),
            {remote: true, class: "icon icon-edit"}) +
    delete_link(quantity_path(q), {remote: true, data: {}})
  end

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
