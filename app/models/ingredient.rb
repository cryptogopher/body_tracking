class Ingredient < ActiveRecord::Base
  belongs_to :composition, inverse_of: :ingredients, required: true
  belongs_to :food, required: true
  belongs_to :part_of, required: false

  validates :ready_ratio, numericality: {greater_than_or_equal_to: 0.0}
  validates :amount, numericality: {greater_than_or_equal_to: 0.0}
end
