class Threshold < QuantityValue
  # Need to specify polymorphic association so :registry_type gets written (see
  # QuantityValue for explanation why it's needed)
  belongs_to :target, inverse_of: :thresholds, polymorphic: true, required: true,
    foreign_key: 'registry_id', foreign_type: 'registry_type'

  validates :value, numericality: true
end
