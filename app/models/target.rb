class Target < ActiveRecord::Base
  CONDITIONS = [:<, :<=, :>, :>=, :==]

  belongs_to :goal, inverse_of: :targets, required: true
  belongs_to :item, polymorphic: true, inverse_of: :targets
  has_many :thresholds, as: :registry, inverse_of: :target, dependent: :destroy,
    validate: true

  validates :thresholds, presence: true
  accepts_nested_attributes_for :thresholds, allow_destroy: true,
    reject_if: proc { |attrs| attrs['quantity_id'].blank? && attrs['value'].blank? }
  validate do
    errors.add(:thresholds, :count_mismatch) unless thresholds.count == arity
    errors.add(:thresholds, :quantity_mismatch) if thresholds.to_a.uniq(&:quantity) != 1
  end
  validates :condition, inclusion: {in: CONDITIONS }
  validates :scope, inclusion: {in: [:day], if: -> { thresholds.first.domain == :diet }}
  validates :effective_from, presence: {unless: :is_binding?}, absence: {if: :is_binding?}

  after_initialize do
    if new_record?
      self.condition = CONDITIONS.first
    end
  end

  def arity
    BigDecimal.method(condition).arity
  end

  def is_binding?
    goal == goal.project.goals.binding
  end
end
