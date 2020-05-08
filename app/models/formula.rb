class Formula < ActiveRecord::Base
  include BodyTracking::FormulaBuilder

  attr_reader :parts, :quantities

  belongs_to :quantity, inverse_of: :formula, required: true
  belongs_to :unit

  validates :code, presence: true
  validate do
    parse.each { |message, params| errors.add(:code, message, params) }
  end

  after_initialize do
    if new_record?
      self.zero_nil = true if self.zero_nil.nil?
    end
  end

  def self.resolve(quantities, items, subitems)
    unchecked_q = quantities.map { |q| [q, nil] }

    # TODO: jesli wartosci nie ma w subitems to pytac w yield (jesli jest block)
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
        deps ||= q.formula.quantities.clone
        deps.reject! { |d| completed_q.has_key?(d) }
        deps.each { |d| unchecked_q << [d, nil] unless unchecked_q.index { |u| u[0] == d } }
      end

      # quantity with formula has all dependencies satisfied, requires calculation
      if deps.empty?
        output_items = items.select { |i| subitems[q][i].nil? }
        input_q = q.formula.quantities
        inputs = input_q.map do |i_q|
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

    completed_q
  end

  def calculate(inputs)
    raise(InvalidInputs, 'No inputs') if inputs.empty?

    quantities = inputs.map { |q, v| [q.name, v.transpose[0]] }.to_h
    length = quantities.values.first.length

    raise(InvalidFormula, 'Invalid formula') unless self.valid?
    raise(InvalidInputs, 'Inputs lengths differ') unless
      quantities.values.all? { |v| v.length == length }

    args = []
    @parts.each do |p|
      code = p[:type] == :indexed ?
        "length.times.map { |_index| #{p[:content]} }" : p[:content]
      args << get_binding(quantities, args, length).eval(code)
    end
    args.last.map { |v| [v, self.unit] }
  end

  private

  def parse
    d_methods = ['abs', 'nil?']
    q_methods = Hash.new(['all', 'lastBefore'])
    q_methods['Meal'] = Meal.attribute_names

    parser = FormulaBuilder.new(self.code, d_methods: d_methods, q_methods: q_methods)
    identifiers, parts = parser.parse
    errors = parser.errors

    quantities = Quantity.where(project: self.quantity.project, name: identifiers.to_a)
    (identifiers - quantities.map(&:name) - q_methods.keys).each do |q|
      errors << [:unknown_quantity, {quantity: q}]
    end

    @parts, @quantities = parts, quantities.to_a if errors.empty?
    errors
  end

  def get_binding(quantities, args, length)
    binding
  end
end
