class Readout < QuantityValue
  # Need to specify polymorphic association so :registry_type gets written (see
  # QuantityValue for explanation why it's needed)
  belongs_to :measurement, inverse_of: :readouts, polymorphic: true, required: true,
    foreign_key: 'registry_id', foreign_type: 'registry_type'

  # Readout uniqueness NOT validated here, see Value for explanation
  validates :value, numericality: true

  delegate :completed_at, to: :measurement
end
