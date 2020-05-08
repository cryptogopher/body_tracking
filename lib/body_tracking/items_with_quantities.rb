module BodyTracking
  module ItemsWithQuantities
    RELATIONS = {
      'Food' => {
        domain: :diet,
        subitem_class: Nutrient,
        association: :food,
        value_field: :amount
      },
      'Measurement' => {
        domain: :measurement,
        subitem_class: Readout,
        association: :measurement,
        value_field: :value
      }
    }

    def filter(filters, requested_q = nil)
      items = all

      if filters[:name].present?
        items = items.where("name LIKE ?", "%#{filters[:name]}%")
      end

      if filters[:visibility].present?
        items = items.where(hidden: filters[:visibility] == "1" ? false : true)
      end

      filter_q =
        if filters[:formula][:code].present?
          owner = proxy_association.owner
          project = owner.is_a?(Project) ? owner : owner.project
          domain = RELATIONS[proxy_association.klass.name][:domain]
          filter_q_attrs = {
            name: 'Filter formula',
            formula_attributes: filters[:formula],
            domain: domain
          }
          project.quantities.new(filter_q_attrs)
        end
      apply_formula = filter_q.present? && filter_q.valid?

      result =
        if requested_q || apply_formula
          computed = items.compute_quantities(requested_q, apply_formula && filter_q)
          requested_q ? computed : computed.keys
        else
          items
        end
      [result, filter_q]
    end

    def compute_quantities(requested_q, filter_q = nil)
      items = all

      relations = RELATIONS[proxy_association.klass.name]
      subitems = Hash.new { |h,k| h[k] = {} }
      relations[:subitem_class].where(relations[:association] => items)
        .includes(:quantity, :unit).order('quantities.lft').each do |s|

        item = s.send(relations[:association])
        subitem_value = s.send(relations[:value_field])
        subitems[s.quantity][item] = [subitem_value, s.unit]
      end

      quantities = (requested_q || Quantity.none) + Array(filter_q)
      completed_q = Formula.resolve(quantities, items, subitems)

      filter_values = completed_q.delete(filter_q)
      items.to_a.keep_if { |i| filter_values[i][0] } if filter_values
      subitems.merge!(completed_q)
      subitem_keys = subitems.keys.sort_by { |q| q.lft }
      items.map { |i| [i, subitem_keys.map { |q| [q, subitems[q][i]] }.to_h] }.to_h
    end
  end
end
