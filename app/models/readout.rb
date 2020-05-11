class Readout < QuantityValue
  belongs_to :measurement, inverse_of: :readouts, required: true

  validates :value, numericality: true
  # Uniqueness NOT validated here, see Value for explanation
  #validates :quantity, uniqueness: {scope: [:measurement_id, :unit_id]}
end
