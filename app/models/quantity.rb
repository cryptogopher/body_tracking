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
  validates :formula, formula: true

  after_initialize do
    if new_record?
      self.primary = false if self.primary.nil?
    end
  end

  def toggle_primary!
    self.toggle!(:primary)
  end

  def formula_quantities
    q_names = Ripper.lex(formula).map do |*, ttype, token|
      token if BodyTracking::Formula::QUANTITY_TTYPES.include?(ttype)
    end.compact
    self.project.quantities.where(name: q_names).to_a
  end

  def calculate(inputs)
    paramed_formula = Ripper.lex(formula).map do |*, ttype, token|
      BodyTracking::Formula::QUANTITY_TTYPES.include?(ttype) ? "params['#{token}']" : token
    end.join
    inputs.map { |i, values| [i, get_binding(values).eval(paramed_formula)] }
  end

  private

  def get_binding(params)
    binding
  end
end
