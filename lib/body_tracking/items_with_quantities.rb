module BodyTracking
  module ItemsWithQuantities
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
          filter_q_attrs = {
            name: 'Filter formula',
            formula_attributes: filters[:formula],
            domain: proxy_association.klass::DOMAIN
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

      subitems = Hash.new { |h,k| h[k] = {} }
      all.with_subitems.order('quantities.lft').each do |i|
        i.subitems.each do |s|
          subitem_value = i.respond_to?(:amount) ? i.amount*s.amount/s.ref_amount : s.value
          subitems[s.quantity][i] = [subitem_value, s.unit]
        end
      end


      requested_q ||= Quantity.none
      unchecked_q = requested_q.map { |q| [q, nil] }
      unchecked_q << [filter_q, nil] if filter_q

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
          next
        end

        # quantity with formula requires refresh of dependencies availability
        if deps.nil? || !deps.empty?
          deps ||= q.formula.quantity_deps.clone
          deps.reject! { |d| completed_q.has_key?(d) }
          deps.each { |d| unchecked_q << [d, nil] unless unchecked_q.index { |u| u[0] == d } }
        end

        # quantity with formula has all dependencies satisfied, requires calculation
        if deps.empty?
          output_items = items.select { |i| subitems[q][i].nil? }
          input_q = q.formula.dependencies
          inputs = input_q.map do |i_q|
            # Yielding for all 'items', not only 'output_items' as completed_q may
            # be used for multiple formulas with different unknowns item sets
            completed_q[i_q] ||= yield(i_q, items) unless i_q.class == Quantity
            values = completed_q[i_q].values_at(*output_items).map { |v| v || [nil, nil] }
            values.map! { |v, u| [v || BigDecimal(0), u] } if q.formula.zero_nil
            [i_q, values]
          end
          begin
            calculated = q.formula.calculate(inputs.to_h)
          rescue Exception => e
            output_items.each { |o_i| subitems[q][o_i] = nil }
            q.formula.errors.add(
              :code, :computation_failed,
              {
                quantity: q.name,
                description: e.message,
                count: output_items.size == subitems[q].size ? 'all' : output_items.size
              }
            )
          else
            output_items.each_with_index { |o_i, idx| subitems[q][o_i] = calculated[idx] }
          end
          unchecked_q.unshift([q, deps])
          next
        end

        # quantity still has unsatisfied dependencies, move to the end of queue
        unchecked_q << [q, deps]
      end

      filter_values = completed_q.delete(filter_q)
      items.to_a.keep_if { |i| filter_values[i][0] } if filter_values
      subitems.merge!(completed_q)
      subitem_keys = subitems.keys.select { |k| k.class == Quantity }.sort_by { |q| q.lft }
      items.map { |i| [i, subitem_keys.map { |q| [q, subitems[q][i]] }.to_h] }.to_h
    end
  end
end
