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
  validates :condition, inclusion: {in: CONDITIONS}
  validates :scope, inclusion: {in: [:ingredient, :meal, :day],
                                if: -> { thresholds.first.quantity.domain == :diet }}
  validates :effective_from, presence: {unless: :is_binding?}, absence: {if: :is_binding?}

  after_initialize do
    if new_record?
      self.condition = CONDITIONS.first
      self.effective_from = Date.current if is_binding?
    end
  end

  delegate :is_binding?, to: :goal
  def arity
    BigDecimal.method(condition).arity
  end
end
