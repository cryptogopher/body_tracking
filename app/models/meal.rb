class Meal < ActiveRecord::Base
  belongs_to :project, required: true

  has_many :ingredients, as: :composition, inverse_of: :composition, dependent: :destroy,
    validate: true
  has_many :foods, through: :ingredients
  validates :ingredients, presence: true
  accepts_nested_attributes_for :ingredients, allow_destroy: true, reject_if: proc { |attrs|
    attrs['food_id'].blank? && attrs['amount'].blank?
  }
  # Ingredient food_id + part_of_id uniqueness validation. Cannot be effectively
  # checked on Ingredient model level.
  validate do
    ingredients = self.ingredients.reject { |i| i.marked_for_destruction? }
      .map { |i| [i.food_id, i.part_of_id] }
    if ingredients.length != ingredients.uniq.length
      errors.add(:ingredients, :duplicated_ingredient)
    end
  end

  def eaten_at
    self[:eaten_at].getlocal if self[:eaten_at]
  end
  alias_attribute :completed_at, :eaten_at

  def eaten_at_date
    self.eaten_at
  end
  def eaten_at_date=(value)
    self.eaten_at = Time.parse(value, self.eaten_at)
  end

  def eaten_at_time
    self.eaten_at
  end
  def eaten_at_time=(value)
    self.eaten_at = Time.parse(value, self.eaten_at)
  end

  def toggle_eaten!
    update(eaten_at: self.eaten_at ? nil : DateTime.current)
  end

  def display_date
    self.eaten_at ? self.eaten_at.to_date : Date.current
  end
end
