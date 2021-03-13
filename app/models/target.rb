class Target < ActiveRecord::Base
  belongs_to :goal, inverse_of: :targets, required: true
  has_one :project, through: :goal, inverse_of: :targets
  belongs_to :quantity, -> { where.not(domain: :target) }, inverse_of: :targets,
    required: true
  belongs_to :item, polymorphic: true, inverse_of: :targets
  has_many :thresholds, -> { joins(:quantity).order(:lft) },
    as: :registry, inverse_of: :target, dependent: :destroy, validate: true

  validates :thresholds, presence: true
  accepts_nested_attributes_for :thresholds, allow_destroy: true,
    reject_if: proc { |attrs| attrs['quantity_id'].blank? && attrs['value'].blank? }
  validate do
    quantities = thresholds.map(&:quantity)
    ancestors = quantities.max_by(&:lft).self_and_ancestors
    errors.add(:thresholds, :count_mismatch) unless quantities.length == ancestors.length
    errors.add(:thresholds, :quantity_mismatch) unless quantities == ancestors
  end
  #validates :scope, inclusion: {in: [:ingredient, :meal, :day], if: -> { quantity&.diet? }}
  validates :effective_from, presence: {if: :is_binding?}, absence: {unless: :is_binding?}

  after_initialize do
    if new_record?
      # Target should be only instantiated through Goal, so :is_binding? will be available
      self.effective_from ||= Date.current if is_binding?
      if self.thresholds.empty?
        self.thresholds.new(quantity: self.goal.project.quantities.target.first)
      end
    end
  end

  delegate :is_binding?, to: :goal
  # NOTE: remove if not used in controller
  def arity
    thresholds.size
  end

  def to_s
    thresholds.last.quantity.description %
      thresholds.map { |t| [t.quantity.name, "#{t.value} [#{t.unit.shortname}]"] }.to_h
  end
end
