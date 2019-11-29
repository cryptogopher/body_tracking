class Readout < ActiveRecord::Base
  belongs_to :measurement, inverse_of: :readouts, required: true
  belongs_to :quantity, required: true
  belongs_to :unit, required: true

  validates :quantity, uniqueness: {scope: [:measurement_id, :unit_id]}
end
