module BodyTracking
  module ItemsWithQuantities
    QUANTITY_DOMAINS = {
      Measurement => :measurement,
      Ingredient => :diet
    }
    VALUE_COLUMNS = {
      Measurement => :value,
      Ingredient => :amount
    }

    def filter(filters, requested_q = nil)
      items = all.where(filters[:scope])

      if filters[:name].present?
        items = items.where("name LIKE ?", "%#{filters[:name]}%")
      end

      if filters[:visibility].present?
        items = items.where(hidden: filters[:visibility] == "1" ? false : true)
      end

      project = proxy_association.owner
      domain = QUANTITY_DOMAINS[proxy_association.klass]
      formula_q = if filters[:formula].present?
                    project.quantities.new(name: '__internal_q',
                                           formula: filters[:formula],
                                           domain: domain)
                  end
      apply_formula = formula_q.present? && formula_q.valid?

      result =
        if requested_q || apply_formula
          computed = items.compute_quantities(requested_q, apply_formula && formula_q)
          requested_q ? computed : [computed[0]]
        else
          [items]
        end
      result.push(formula_q)
    end

    def compute_quantities(requested_q, filter_q = nil)
      items = all
      requested_q ||= Quantity.none
      unchecked_q = requested_q.map { |q| [q, nil] }
      unchecked_q << [filter_q, nil] if filter_q

      subitems = Hash.new { |h,k| h[k] = {} }
      item_class = proxy_association.klass
      subitem_type = item_class.nested_attributes_options.keys.first.to_s
      subitem_reflection = item_class.reflections[subitem_type]
      subitem_class = subitem_reflection.klass
      subitems_scope = subitem_class.where(subitem_reflection.options[:inverse_of] => items)
      item_foreign_key = subitem_reflection.foreign_key
      subitems_scope.includes(:quantity, :unit)
        .order('quantities.lft')
        .pluck(item_foreign_key, 'quantities.name', VALUE_COLUMNS[item_class],
               'units.shortname')
        .each { |item_id, q_name, a, u_id| subitems[q_name][item_id] = [a, u_id] }

      extra_q = subitems.keys - requested_q.pluck(:name)

      completed_q = {}
      # FIXME: loop should finish unless there is circular dependency in formulas
      # for now we don't guard against that
      while !unchecked_q.empty?
        q, deps = unchecked_q.shift

        # quantity not computable (no formula) or not requiring calculation/computed
        if !q.formula || q.formula.errors.any? || !q.formula.valid? ||
            (subitems[q.name].length == items.count)
          completed_q[q.name] = subitems.delete(q.name) { {} }
          completed_q[q.name].default = [nil, nil]
          next
        end

        # quantity with formula requires refresh of dependencies availability
        if deps.nil? || !deps.empty?
          deps ||= q.formula.quantities
          deps.reject! { |q| completed_q.has_key?(q.name) }
          deps.each { |q| unchecked_q << [q, nil] unless unchecked_q.index { |u| u[0] == q } }
        end

        # quantity with formula has all dependencies satisfied, requires calculation
        if deps.empty?
          output_ids = items.select { |i| subitems[q.name][i.id].nil? }.map(&:id)
          input_q = q.formula.quantities
          inputs = input_q.map { |i_q| [i_q, completed_q[i_q.name].values_at(*output_ids)] }
          begin
            calculated = q.formula.calculate(inputs.to_h)
          rescue Exception => e
            output_ids.each { |oid| subitems[q.name][oid] = BigDecimal::NAN }
            q.formula.errors.add(:code, :computation_failed,
              {quantity: q.name, description: e.message, count: output_ids.size})
          else
            output_ids.each_with_index { |oid, idx| subitems[q.name][oid] = calculated[idx] }
          end
          unchecked_q.unshift([q, deps])
          next
        end

        # quantity still has unsatisfied dependencies, move to the end of queue
        unchecked_q << [q, deps]
      end

      all_q = subitems.merge(completed_q)
      [
        filter_q ? items.to_a.keep_if { |i| all_q[filter_q.name][i.id][0] } : items,
        items.map { |i| requested_q.map { |q| [q.name, all_q[q.name][i.id]] } },
        items.map do |i|
          extra_q.map { |q_name| [q_name, all_q[q_name][i.id]] if all_q[q_name][i.id] }
        end
      ]
    end
  end
end
