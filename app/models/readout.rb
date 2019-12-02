class Readout < ActiveRecord::Base
  belongs_to :measurement, inverse_of: :readouts, required: true
  belongs_to :quantity, required: true
  belongs_to :unit, required: true

  # Uniqueness is checked exclusively on Measurement level. Otherwise validation
  # may not pass when multiple Readouts are updated at once and some quantity_id
  # is moved from one Readout to the other (without duplication).
  # For the same reason Readout quantity_id uniqueness has to be checked by
  # Measurement when multiple Readouts are first created. Relying on this check
  # only would make all newly added records pass as valid despite duplications.
  #validates :quantity, uniqueness: {scope: [:measurement_id, :unit_id]}

  validates :value, numericality: true
end
