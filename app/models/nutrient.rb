class Nutrient < ActiveRecord::Base
  belongs_to :ingredient, inverse_of: :nutrients
  belongs_to :quantity
  belongs_to :unit

  # disabled to avoid loop with Ingredient 'validates_associated :nutrients'
  #validates :ingredient, presence: true, associated: true
  validates :quantity, presence: true, associated: true, uniqueness: {scope: :ingredient_id}
  validates :amount, numericality: {greater_than: 0}
  validates :unit, presence: true, associated: true
end
