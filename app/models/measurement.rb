class Measurement < ActiveRecord::Base
  belongs_to :project, required: true
  belongs_to :source, required: false

  has_many :readouts, inverse_of: :measurement, dependent: :destroy, validate: true
  validates :readouts, presence: true
  accepts_nested_attributes_for :readouts, allow_destroy: true, reject_if: proc { |attrs|
    attrs['quantity_id'].blank?
  }
  # Readout (quantity_id, unit_id) pair uniqueness check for nested attributes
  validate do
    quantities = self.readouts.map { |r| [r.quantity_id, r.unit_id] }
    if quantities.length != quantities.uniq.length
      errors.add(:readouts, :duplicated_quantity_unit_pair)
    end
  end

  validates :name, presence: true, uniqueness: {scope: :project_id}

  after_initialize do
    if new_record?
      self.hidden = false if self.hidden.nil?
    end
  end

  def toggle_hidden!
    self.toggle!(:hidden)
  end
end
