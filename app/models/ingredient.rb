class Ingredient < ActiveRecord::Base
  belongs_to :composition, inverse_of: :ingredients, polymorphic: true, required: true
  belongs_to :food, required: true
  belongs_to :part_of, required: false

  validates :ready_ratio, numericality: {greater_than_or_equal_to: 0.0}
  validates :amount, numericality: {greater_than_or_equal_to: 0.0}

  after_initialize do
    if new_record?
      self.ready_ratio ||= BigDecimal.new('1.0')
    end
  end
end
