class Quantity < ActiveRecord::Base
  enum domain: {
    diet: 0,
    measurement: 1,
    exercise: 2
  }

  acts_as_nested_set dependent: :destroy, scope: :project
  belongs_to :project, inverse_of: :quantities, required: false
  has_many :nutrients, dependent: :restrict_with_error
  has_many :readouts, dependent: :restrict_with_error
  has_many :values, class_name: 'QuantityValue', dependent: :restrict_with_error
  has_many :exposures, dependent: :destroy

  has_one :formula, inverse_of: :quantity, dependent: :destroy, validate: true
  accepts_nested_attributes_for :formula, allow_destroy: true,
    reject_if: proc { |attrs| attrs['id'].blank? && attrs['code'].blank? }
  before_validation do
    formula.mark_for_destruction if formula.present? && formula.code.blank?
  end

  # TODO: :name should be validated against model names (Meal, Ingredient etc.)
  # Quantity :name uniqueness relaxed to formulas unambiguity
  validates :name, presence: true, uniqueness: {scope: [:project_id, :parent_id]}
  # Formula ambiguity vlidation delayed after save, as otherwise there seems to
  # be no other way to validate against newly changed :name
  after_save do
    next unless name_changed? || changes.empty?
    formulas = Formula.joins(:quantity).where(quantities: {project_id: project})
      .where('formulas.code LIKE ?', "%#{name}%").includes(:quantity)
    next unless formulas.exists?

    quantity_names = formulas.reject(&:valid?)
      .select { |f| f.errors.details[:code].any? { |e| e[:error] == :ambiguous_dependency } }
      .map { |f| "'#{f.quantity.name}'" }.join(', ')

    unless quantity_names.blank?
      errors.add(:name, :name_ambiguous, names: quantity_names)
      raise ActiveRecord::RecordInvalid.new(self)
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
