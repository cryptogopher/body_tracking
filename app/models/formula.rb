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
