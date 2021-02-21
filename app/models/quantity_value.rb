class QuantityValue < ActiveRecord::Base
  # Requirement validation for :registry left to subclasses
  # Polymorphic registry (including :registry_type) is required - despite 1:1
  # mapping between Nutrient:Food, Readout:Measurement, Threshold:Target ... -
  # to allow for accessing registry item without knowing QuantityValue (subitem)
  # type, e.g. qv.registry.completed_at
  belongs_to :registry, polymorphic: true
  belongs_to :quantity, required: true
  validate do
    errors.add(:quantity, :domain_mismatch) unless self.class::DOMAIN == quantity.domain
  end
  belongs_to :unit, required: true

  # Uniqueness is checked exclusively on the other end of association level.
  # Otherwise validation may not pass when multiple Values are updated at once
  # and some quantity_id is moved from one Value to the other (without duplication).
  # For the same reason Value quantity_id uniqueness has to be checked on the
  # other end when multiple Values are first created. Relying on local check
  # only would make all newly added records pass as valid despite duplications.
  #validates :quantity, uniqueness: {scope: [:measurement_id, :unit_id]}
  #validates :quantity, uniqueness: {scope: :food_id}
end
