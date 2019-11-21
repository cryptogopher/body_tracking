class Quantity < ActiveRecord::Base
  include BodyTracking::Formula

  enum domain: {
    diet: 0,
    measurement: 1,
    exercise: 2
  }

  acts_as_nested_set dependent: :destroy, scope: :project
  belongs_to :project, required: false

  validates :name, presence: true, uniqueness: {scope: :project_id}
  validates :domain, inclusion: {in: domains.keys}
  validate if: -> { parent.present? } do
    errors.add(:parent, :parent_domain_mismatch) unless domain == parent.domain
  end
  validates :formula, formula: {allow_nil: true}

  after_initialize do
    if new_record?
      self.primary = false if self.primary.nil?
    end
  end

  def toggle_primary!
    self.toggle!(:primary)
  end

  def formula_quantities
    Formula.new(self.project, self.formula).get_quantities
  end

  def calculate(inputs)
    Formula.new(self.project, self.formula).calculate(inputs)
  end

  def self.filter(project, filters)
    quantities = all

    if filters[:domain].present?
      quantities = quantities.where(domain: domains[filters[:domain]])
    end

    quantities
  end
end
