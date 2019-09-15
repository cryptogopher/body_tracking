class Ingredient < ActiveRecord::Base
  enum group: {
    meat: 0
  }

  belongs_to :project
  belongs_to :ref_unit, class_name: 'Unit'

  has_many :nutrients, inverse_of: :ingredient, dependent: :destroy
  accepts_nested_attributes_for :nutrients, allow_destroy: true, reject_if: proc { |attrs|
    attrs['quantity_id'].blank? && attrs['amount'].blank?
  }
  validates_associated :nutrients
  # Nutrient quantity_id uniqueness check for nested attributes
  validate on: :create do
    quantities = self.nutrients.map { |n| n.quantity_id }
    if quantities.length != quantities.uniq.length
      errors.add(:nutrients, :duplicated_quantity)
    end
  end

  validates :project, associated: true
  validates :name, presence: true, uniqueness: {scope: :project_id}
  validates :ref_amount, numericality: {greater_than: 0}
  validates :ref_unit, presence: true, associated: true
  validates :group, inclusion: {in: groups.keys}

  after_initialize do
    if new_record?
      units = self.project.units
      self.ref_unit ||= units.find_by(shortname: 'g') || units.first
    end
  end

end
