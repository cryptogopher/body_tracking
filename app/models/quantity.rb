class Quantity < ActiveRecord::Base
  enum domain: {
    diet: 0,
    measurement: 1,
    exercise: 2
  }

  acts_as_nested_set dependent: :destroy, scope: :project
  belongs_to :project, required: false
  has_many :nutrients, dependent: :restrict_with_error
  has_many :readouts, dependent: :restrict_with_error
  has_many :values, class_name: 'QuantityValue', dependent: :restrict_with_error
  has_many :exposures, dependent: :destroy

  has_one :formula, inverse_of: :quantity, dependent: :destroy, validate: true
  accepts_nested_attributes_for :formula, allow_destroy: true,
    reject_if: proc { |attrs| attrs['code'].blank? }

  validates :name, presence: true
  # Quantity :name uniqueness relaxed to formulas unambiguity
  validate if: -> { name_changed? } do
    formulas = project.formulas.where('formulas.code LIKE ?', "%#{name}%").includes(:quantity)
    # FIXME: should actually parse formulas in formulas and check for exact name match;
    # current code is just quick'n'dirty partial solution
    if formulas.exists?
      quantity_names = formulas.map { |f| "'#{f.quantity.name}'" }.join(',')
      errors.add(:name, :name_ambiguous, names: quantity_names)
    end
  end
  validates :domain, inclusion: {in: domains.keys}
  validate if: -> { parent.present? } do
    errors.add(:parent, :parent_domain_mismatch) unless domain == parent.domain
  end

  after_initialize do
    if new_record?
      self.domain ||= :diet
    end
  end

  def movable?(direction)
    case direction
    when :up
      self.left_sibling.present?
    when :down
      self.right_sibling.present?
    when :left
      self.parent.present?
    when :right
      left = self.left_sibling
      left.present? && (left.domain == self.domain)
    else
      false
    end
  end

  # TODO: move as an association extension module
  def self.filter(project, filters)
    quantities = all

    if filters[:domain].present?
      quantities = quantities.where(domain: domains[filters[:domain]])
    end

    quantities
  end
end
