class Nutrient < QuantityValue
  belongs_to :food, inverse_of: :nutrients, required: true

  validates :value, numericality: {greater_than_or_equal_to: 0.0}
  # Uniqueness NOT validated here, see Value for explanation
  #validates :quantity, uniqueness: {scope: :food_id}

  alias_attribute :amount, :value
end
