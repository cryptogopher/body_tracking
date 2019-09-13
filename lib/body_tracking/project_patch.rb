module BodyTracking
  module ProjectPatch
    Project.class_eval do
      has_many :ingredients, dependent: :destroy

      has_many :quantities, -> { order "lft" }, dependent: :destroy
      has_many :units, dependent: :destroy
    end
  end
end

