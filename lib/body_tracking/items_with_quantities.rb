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
                    project.quantities.new(name: 'Filter formula',
                                           formula_attributes: filters[:formula],
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

      item_class = proxy_association.klass
      subitem_type = item_class.nested_attributes_options.keys.first.to_s
      subitem_reflection = item_class.reflections[subitem_type]
      subitem_class = subitem_reflection.klass
      subitems_scope = subitem_class.where(subitem_reflection.options[:inverse_of] => items)
      subitems = Hash.new { |h,k| h[k] = {} }
      subitems_scope.includes(:quantity, :unit).order('quantities.lft').each do |s|
        item_id = s.send(subitem_reflection.foreign_key)
        subitem_value = s.send(VALUE_COLUMNS[item_class])
        subitems[s.quantity][item_id] = [subitem_value, s.unit]
      end

      extra_q = subitems.keys - requested_q

      completed_q = {}
      # FIXME: loop should finish unless there is circular dependency in formulas
      # for now we don't guard against that
      while !unchecked_q.empty?
        q, deps = unchecked_q.shift

        # quantity not computable: no formula/invalid formula (syntax error/runtime error)
        # or not requiring calculation/computed
        if !q.formula || q.formula.errors.any? || !q.formula.valid? ||
            (subitems[q].length == items.count)
          completed_q[q] = subitems.delete(q) { {} }
          completed_q[q].default = [nil, nil]
          next
        end

        # quantity with formula requires refresh of dependencies availability
        if deps.nil? || !deps.empty?
          deps ||= q.formula.quantities.clone
          deps.reject! { |d| completed_q.has_key?(d) }
          deps.each { |d| unchecked_q << [d, nil] unless unchecked_q.index { |u| u[0] == d } }
        end

        # quantity with formula has all dependencies satisfied, requires calculation
        if deps.empty?
          output_ids = items.select { |i| subitems[q][i.id].nil? }.map(&:id)
          input_q = q.formula.quantities
          inputs = input_q.map do |i_q|
            values = completed_q[i_q].values_at(*output_ids)
            values.map! { |v, u| [v || BigDecimal(0), u] } if q.formula.zero_nil
            [i_q, values]
          end
          begin
            calculated = q.formula.calculate(inputs.to_h)
          rescue Exception => e
            output_ids.each { |oid| subitems[q][oid] = [BigDecimal::NAN, nil] }
            q.formula.errors.add(
              :code, :computation_failed,
              {
                quantity: q.name,
                description: e.message,
                count: output_ids.size == subitems[q].size ? 'all' : output_ids.size
              }
            )
          else
            output_ids.each_with_index { |oid, idx| subitems[q][oid] = calculated[idx] }
          end
          unchecked_q.unshift([q, deps])
          next
        end

        # quantity still has unsatisfied dependencies, move to the end of queue
        unchecked_q << [q, deps]
      end

      all_q = subitems.merge(completed_q)
      [
        filter_q ? items.to_a.keep_if { |i| all_q[filter_q][i.id][0] } : items,
        items.map { |i| requested_q.map { |q| [q, all_q[q][i.id]] } },
        items.map { |i| extra_q.map     { |q| [q, all_q[q][i.id]] } }
      ]
    end
  end
end
