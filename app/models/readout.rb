class Readout < QuantityValue
  belongs_to :measurement, foreign_key: 'registry_id', inverse_of: :readouts, required: true

  # Uniqueness NOT validated here, see Value for explanation
  #validates :quantity, uniqueness: {scope: [:measurement_id, :unit_id]}
  validates :value, numericality: true
end
