class Nutrient < QuantityValue
  belongs_to :food, foreign_key: 'registry_id', inverse_of: :nutrients, required: true

  # Uniqueness NOT validated here, see Value for explanation
  #validates :quantity, uniqueness: {scope: :food_id}
  validates :value, numericality: {greater_than_or_equal_to: 0.0}

  alias_attribute :amount, :value
  delegate :ref_amount, to: :food
end
