class Formula < ActiveRecord::Base
  include BodyTracking::FormulaBuilder

  attr_reader :parts, :quantity_deps, :model_deps

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

  def calculate(inputs)
    raise(InvalidInputs, 'No inputs') if inputs.empty?

    deps = inputs.map { |q, v| [q.name, QuantityInput.new(q, v.transpose.first)] }.to_h
    length = deps.values.first.length

    raise(InvalidFormula, 'Invalid formula') unless self.valid?
    raise(InvalidInputs, 'Inputs lengths differ') unless
      deps.values.all? { |v| v.length == length }

    args = []
    @parts.each do |p|
      code = p[:type] == :indexed ?
        "length.times.map { |_index| #{p[:content]} }" : p[:content]
      args << get_binding(deps, args, length).eval(code)
    end
    args.last.map { |v| [v, self.unit] }
  end

  def dependencies
    @quantity_deps + @model_deps
  end

  private

  class QuantityInput < Array
    def initialize(q, *args)
      super(*args)
      @quantity = q
    end

    def lastBefore(timepoints)
      # NOTE: maybe optimize query, limiting range by min-max timepoints?
      # impact on caching?
      values = @quantity.values.includes(:registry)
        .map { |qv| [qv.registry.completed_at, qv.value] }.sort_by(&:first)

      return [nil]*timepoints.length if values.empty?

      vindex = 0
      lastval = nil
      timepoints.each_with_index.sort_by { |t, i| t || Time.current }.map do |time, index|
        while vindex < values.length && values[vindex].first <= time
          lastval = values[vindex].last
          vindex += 1
        end
        #vindex += values[vindex..-1].find_all { |vtime, v| lastval = v; vtime <= time }
        #.length
        [lastval, index]
      end.sort_by(&:last).transpose.first
    end
  end

  def parse
    d_methods = ['abs', 'nil?']
    q_methods = Hash.new(['all', 'lastBefore'])
    q_methods['Meal'] = Meal.attribute_names

    parser = FormulaBuilder.new(self.code, d_methods: d_methods, q_methods: q_methods)
    identifiers, parts = parser.parse
    errors = parser.errors

    project = self.quantity.project
    quantities =
      if project
        # This is required to properly validate with in-memory records, e.g.
        # during import of defaults
        project.quantities.select { |q| identifiers.include?(q.name) }
      else
        Quantity.where(project: nil, name: identifiers.to_a)
      end
    identifiers -= quantities.map(&:name)
    models = identifiers.map(&:safe_constantize).compact || []
    (identifiers - models.map(&:class_name)).each do |i|
      errors << [:unknown_dependency, {identifier: i}]
    end

    @parts, @quantity_deps, @model_deps = parts, quantities.to_a, models if errors.empty?
    errors
  end

  def get_binding(quantities, parts, length)
    binding
  end
end
