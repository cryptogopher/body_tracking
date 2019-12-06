module BodyTracking
  module ProjectPatch
    Project.class_eval do
      has_many :measurements, -> { order "taken_at DESC" }, dependent: :destroy
      has_many :ingredients, -> { order "name" }, dependent: :destroy

      has_many :sources, dependent: :destroy
      has_many :quantities, -> { order "lft" }, dependent: :destroy
      has_many :units, dependent: :destroy
    end
  end
end

