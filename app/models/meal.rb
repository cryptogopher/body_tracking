class Meal < ActiveRecord::Base
  belongs_to :project, required: true

  has_many :ingredients, as: :composition, dependent: :destroy
  has_many :foods, through: :ingredients
end
