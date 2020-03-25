class Formula < ActiveRecord::Base
  include BodyTracking::FormulaBuilder

  attr_reader :parts, :quantities

  belongs_to :quantity, inverse_of: :formula, required: true
  belongs_to :unit, required: true

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
        "length.times.map { |index| #{p[:content]} }" : p[:content]
      args << get_binding(quantities, args, length).eval(code)
    end
    args.last.map { |v| [v, nil] }
  end

  private

  def parse
    parser = FormulaBuilder.new(self.code)
    identifiers, parts = parser.parse
    errors = parser.errors

    quantities = Quantity.where(project: self.quantity.project, name: identifiers)
    (identifiers - quantities.map(&:name)).each do |q|
      errors << [:unknown_quantity, {quantity: q}]
    end

    @parts, @quantities = parts, quantities.to_a if errors.empty?
    errors
  end

  def get_binding(quantities, args, length)
    binding
  end
end
