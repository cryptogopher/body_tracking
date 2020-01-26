class Quantity < ActiveRecord::Base
  include BodyTracking::Formula

  enum domain: {
    diet: 0,
    measurement: 1,
    exercise: 2
  }

  # Has to go before any 'dependent:' association
  before_destroy do
    # FIXME: disallow destruction if any object depends on this quantity
    nil
  end

  acts_as_nested_set dependent: :destroy, scope: :project
  belongs_to :project, required: false
  has_and_belongs_to_many :column_views
  has_many :readouts

  validates :name, presence: true, uniqueness: {scope: :project_id}
  validates :domain, inclusion: {in: domains.keys}
  validate if: -> { parent.present? } do
    errors.add(:parent, :parent_domain_mismatch) unless domain == parent.domain
  end
  validates :formula, formula: {allow_nil: true}

  after_initialize do
    if new_record?
      self.domain ||= :diet
    end
    @formula = Formula.new(self.project, self.formula)
  end

  def formula=(value)
    @formula = Formula.new(self.project, value)
    super(value)
  end

  def formula_valid?
    @formula.valid?
  end

  def formula_quantities
    @formula.get_quantities
  end

  def calculate(inputs)
    @formula.calculate(inputs)
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

  def self.filter(project, filters)
    quantities = all

    if filters[:domain].present?
      quantities = quantities.where(domain: domains[filters[:domain]])
    end

    quantities
  end
end
