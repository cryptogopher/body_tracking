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

  # Uniqueness is checked exclusively in the model accepting nested attributes.
  # Otherwise validation may give invalid results for batch create/update actions,
  # because either:
  # * in-memory records in batch are not unique but validates_uniqueness_of only
  #   validates every single in-memory record against database content (and so
  #   misses non-uniqueness inside batch)
  # or
  # * batch update action may include swapping of unique values of 2 or more
  #   records and checking in-memory records for uniqueness one-by-one against
  #   database will falsely signal uniqueness violation
end
