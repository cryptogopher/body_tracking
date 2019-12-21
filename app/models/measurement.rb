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

  after_save :cleanup_column_view, if: :name_changed?

  # Destroy ColumnView after last Measurement destruction
  after_destroy do
    unless self.project.measurements.exists?(name: self.name)
      self.column_view.destroy!
    end
  end

  def column_view
    self.project.column_views
      .find_or_create_by(name: self.name, domain: ColumnView.domains[:measurement])
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

  private

  # Copy/rename ColumnView on Measurement rename
  def cleanup_column_view
    old_column_view = self.project.column_views
      .find_by(name: self.name_was, domain: ColumnView.domains[:measurement])
    return unless old_column_view

    if self.project.measurements.exists?(name: self.name_was)
      self.column_view.quantities.append(old_column_view.quantities).save!
    else
      old_column_view.update!(name: self.name)
    end
  end
end
