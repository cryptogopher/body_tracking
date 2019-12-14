module BodyTracking
  module ProjectPatch
    Project.class_eval do
      has_many :measurements, -> { order "taken_at DESC" }, dependent: :destroy, extend: ItemsWithQuantities
      has_many :ingredients, -> { order "name" }, dependent: :destroy

      has_many :sources, dependent: :destroy
      has_many :column_views, dependent: :destroy
      has_many :quantities, -> { order "lft" }, dependent: :destroy
      has_many :units, dependent: :destroy

      def nutrients_column_view
        self.column_views.find_or_create_by(name: 'Nutrients', domain: :diet)
      end
    end
  end
end

