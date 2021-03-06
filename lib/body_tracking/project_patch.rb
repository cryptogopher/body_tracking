module BodyTracking::ProjectPatch
  Project.class_eval do
    has_many :sources, dependent: :destroy
    # TODO: includes(:parent) ?
    has_many :quantities, -> { order "lft" }, inverse_of: :project, dependent: :destroy
    has_many :formulas, through: :quantities
    has_many :units, dependent: :destroy

    has_many :foods, -> { order "foods.name" }, dependent: :destroy,
      extend: BodyTracking::ItemsWithQuantities
    has_many :nutrient_exposures, -> { where view_type: "Nutrient" }, dependent: :destroy,
      foreign_key: :view_id, foreign_type: :view_type,
      class_name: 'Exposure', extend: BodyTracking::TogglableExposures
    has_many :nutrient_quantities, -> { order "lft" }, through: :nutrient_exposures,
      source: 'quantity'

    has_many :measurement_routines, dependent: :destroy
    has_many :measurements, -> { order "taken_at DESC" }, through: :measurement_routines,
      extend: BodyTracking::ItemsWithQuantities

    has_many :meals, -> { order "eaten_at DESC" }, dependent: :destroy
    has_many :meal_ingredients, through: :meals, source: 'ingredients',
      extend: BodyTracking::ItemsWithQuantities
    has_many :meal_foods, through: :meal_ingredients, source: 'food',
      extend: BodyTracking::ItemsWithQuantities
    has_many :meal_exposures, -> { where view_type: "Meal" }, dependent: :destroy,
      foreign_key: :view_id, foreign_type: :view_type,
      class_name: 'Exposure', extend: BodyTracking::TogglableExposures
    has_many :meal_quantities, -> { order "lft" }, through: :meal_exposures,
      source: 'quantity'

    has_many :goals, inverse_of: :project, dependent: :destroy do
      def binding
        find_or_create_by!(is_binding: true) do |goal|
          goal.name = I18n.t('goals.binding.name')
          goal.description = I18n.t('goals.binding.description')
        end
      end
    end
    has_many :targets, through: :goals, inverse_of: :project
  end
end
