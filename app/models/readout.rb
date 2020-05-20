class Readout < QuantityValue
  belongs_to :measurement, foreign_key: 'registry_id', foreign_type: 'registry_type',
    inverse_of: :readouts, polymorphic: true, required: true

  # Uniqueness NOT validated here, see Value for explanation
  #validates :quantity, uniqueness: {scope: [:measurement_id, :unit_id]}
  validates :value, numericality: true

  delegate :completed_at, to: :measurement
end
