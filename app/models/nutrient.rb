class Nutrient < ActiveRecord::Base
  belongs_to :food, inverse_of: :nutrients, required: true
  belongs_to :quantity, required: true
  belongs_to :unit, required: true

  validates :quantity, uniqueness: {scope: :food_id}
  validates :amount, numericality: {greater_than_or_equal_to: 0.0}
end
