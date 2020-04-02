class Measurement < ActiveRecord::Base
  belongs_to :routine, required: true, inverse_of: :measurements,
    class_name: 'MeasurementRoutine'
  accepts_nested_attributes_for :routine, allow_destroy: true, reject_if: proc { |attrs|
    attrs['name'].blank?
  }
  after_destroy { self.routine.destroy if self.routine.measurements.empty? }
  has_one :project, through: :routine

  belongs_to :source, required: false

  has_many :readouts, inverse_of: :measurement, dependent: :destroy, validate: true
  validates :readouts, presence: true
  accepts_nested_attributes_for :readouts, allow_destroy: true, reject_if: proc { |attrs|
    attrs['quantity_id'].blank? && attrs['value'].blank?
  }
  # Readout quantity_id + unit_id uniqueness validation. Cannot be effectively
  # checked on Readout model level.
  validate do
    quantities = self.readouts.reject { |r| r.marked_for_destruction? }
      .map { |r| [r.quantity_id, r.unit_id] }
    if quantities.length != quantities.uniq.length
      errors.add(:readouts, :duplicated_quantity_unit_pair)
    end
  end

  validates :taken_at, presence: true

  after_initialize do
    if new_record?
      self.taken_at = Time.now
    end
  end

  def taken_at_date
    self.taken_at.getlocal
  end
  def taken_at_date=(value)
    self.taken_at = Time.parse(value, self.taken_at)
  end

  def taken_at_time
    self.taken_at.getlocal
  end
  def taken_at_time=(value)
    self.taken_at = Time.parse(value, self.taken_at)
  end
end
