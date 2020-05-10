class Food < ActiveRecord::Base
  enum group: {
    other: 0,
    dish: 1,
    recipe: 2,
    meat: 3
  }

  # Has to go before any 'dependent:' association
  before_destroy do
    # FIXME: disallow destruction if any object depends on this quantity
    nil
  end

  belongs_to :project, required: true
  belongs_to :ref_unit, class_name: 'Unit', required: true
  belongs_to :source, required: false
  has_many :ingredients, dependent: :restrict_with_error

  has_many :nutrients, inverse_of: :food, dependent: :destroy, validate: true
  validates :nutrients, presence: true
  accepts_nested_attributes_for :nutrients, allow_destroy: true, reject_if: proc { |attrs|
    attrs['quantity_id'].blank? && attrs['amount'].blank?
  }
  # Nutrient quantity_id uniqueness check for nested attributes
  validate do
    quantities = self.nutrients.reject { |n| n.marked_for_destruction? }
      .map { |n| n.quantity_id  }
    if quantities.length != quantities.uniq.length
      errors.add(:nutrients, :duplicated_quantity)
    end
  end

  validates :name, presence: true, uniqueness: {scope: :project_id}
  validates :ref_amount, numericality: {greater_than: 0}
  validates :group, inclusion: {in: groups.keys}

  scope :visible, -> { where(hidden: false) }
  scope :hidden, -> { where(hidden: true) }

  after_initialize do
    if new_record?
      self.ref_amount ||= 100
      units = self.project.units
      self.ref_unit ||= units.find_by(shortname: 'g') || units.first
      self.group ||= :other
      self.hidden = false if self.hidden.nil?
    end
  end

  def toggle_hidden!
    self.toggle!(:hidden)
  end
end
