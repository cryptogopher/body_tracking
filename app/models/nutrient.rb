class Nutrient < ActiveRecord::Base
  belongs_to :ingredient, inverse_of: :nutrients, required: true
  belongs_to :quantity, required: true
  belongs_to :unit, required: true

  validates :quantity, uniqueness: {scope: :ingredient_id}
  validates :amount, numericality: {greater_than_or_equal_to: 0.0}

  after_initialize do
    if new_record?
      self.unit ||= self.ingredient.ref_unit
    end
  end
end
