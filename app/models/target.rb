class Target < ActiveRecord::Base
  belongs_to :goal, inverse_of: :targets
  belongs_to :item, polymorphic: true, inverse_of: :targets
  has_many :thresholds, as: :registry, inverse_of: :target, dependent: :destroy,
    validate: true

  validates :thresholds, presence: true
  accepts_nested_attributes_for :thresholds, allow_destroy: true,
    reject_if: proc { |attrs| attrs['quantity_id'].blank? && attrs['value'].blank? }
  # TODO: validate thresholds count according to condition type
  validates :condition, inclusion: {in: [:<, :<=, :>, :>=, :==]}
  validates :scope, inclusion: {in: [:day], if: -> { thresholds.first.domain == :diet }}
  validates :effective_from, presence: {unless: -> { goal.present? }},
    absence: {if: -> { goal.present? }}

  after_initialize do
    if new_record?
      self.condition = :<
    end
  end

  def arity
    BigDecimal.method(condition).arity
  end
end
