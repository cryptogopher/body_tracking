module BodyTracking::ProjectPatch
  Project.class_eval do
    has_many :meals, -> { order "eaten_at DESC" }, dependent: :destroy

    has_many :measurement_routines, dependent: :destroy
    has_many :measurements, -> { order "taken_at DESC" }, dependent: :destroy,
      extend: BodyTracking::ItemsWithQuantities, through: :measurement_routines
    has_many :foods, -> { order "name" }, dependent: :destroy,
      extend: BodyTracking::ItemsWithQuantities

    has_many :sources, dependent: :destroy
    has_many :quantities, -> { order "lft" }, dependent: :destroy
    has_many :units, dependent: :destroy

    has_many :nutrient_columns, as: :column_view, dependent: :destroy,
      class_name: 'QuantityColumn', extend: BodyTracking::TogglableColumns
    has_many :nutrient_quantities, -> { order "lft" }, through: :nutrient_columns,
      source: 'quantity'
  end
end
