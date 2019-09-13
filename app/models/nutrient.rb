class Nutrient < ActiveRecord::Base
  belongs_to :ingredient

  validates :ingredient, presence: true, associated: true
  validates :quantity, presence: true, associated: true
  validates :amount, numericality: {greater_than: 0}
  validates :unit, presence: true, associated: true
end
