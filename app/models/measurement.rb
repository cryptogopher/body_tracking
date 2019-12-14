class Measurement < ActiveRecord::Base
  belongs_to :project, required: true
  belongs_to :source, required: false

  has_many :readouts, inverse_of: :measurement, dependent: :destroy, validate: true
  validates :readouts, presence: true
  accepts_nested_attributes_for :readouts, allow_destroy: true, reject_if: proc { |attrs|
    attrs['quantity_id'].blank? && attrs['value'].blank?
  }
  # Readout quantity_id + unit_id uniqueness validation. Cannot be effectively
  # checked on Readout model level.
  validate do
    quantities = self.readouts.map do |r|
      [r.quantity_id, r.unit_id] unless r.marked_for_destruction?
    end
    if quantities.length != quantities.uniq.length
      errors.add(:readouts, :duplicated_quantity_unit_pair)
    end
  end

  validates :name, presence: true
  validates :taken_at, presence: true

  after_initialize do
    if new_record?
      self.hidden = false if self.hidden.nil?
      self.taken_at = Time.now
    end
  end

  # Copy/rename ColumnView on Measurement rename
  after_save do
    old_column_view = self.project.column_views
      .find_by(name: self.name_was, domain: :measurement)
    return unless old_column_view

    if self.project.measurements.exists?(name: self.name_was)
      return unless old_column_view.quantities.exist?
      self.column_view.quantities.create(old_column_view.quantities)
      self.column_view.save!
    else
      old_column_view.name = self.name
      old_column_view.save!
    end
  end, if: :name_changed?

  # Destroy ColumnView after last Measurement destruction
  after_destroy do
    unless self.project.measurements.exists?(name: self.name)
      self.column_view.destroy!
    end
  end

  def column_view
    self.project.column_views.find_or_create_by(name: self.name, domain: :measurement)
  end

  def toggle_hidden!
    self.toggle!(:hidden)
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
