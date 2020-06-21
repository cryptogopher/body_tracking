class Threshold < QuantityValue
  belongs_to :target, foreign_key: 'registry_id', foreign_type: 'foreign_type',
    inverse_of: :thresholds, polymorphic: true, required: true

  validates :value, numericality: true
end
