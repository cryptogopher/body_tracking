class Nutrient < QuantityValue
  # Need to specify polymorphic association so :registry_type gets written (see
  # QuantityValue for explanation why it's needed)
  belongs_to :food, inverse_of: :nutrients, polymorphic: true, required: true,
    foreign_key: 'registry_id', foreign_type: 'registry_type'

  # Uniqueness NOT validated here, see Value for explanation
  #validates :quantity, uniqueness: {scope: :food_id}
  validates :value, numericality: {greater_than_or_equal_to: 0.0}

  alias_attribute :amount, :value
  delegate :ref_amount, to: :food
end
