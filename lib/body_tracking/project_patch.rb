module BodyTracking
  module ProjectPatch
    Project.class_eval do
      has_many :units, dependent: :destroy
      has_many :quantities, -> { order "lft" }, dependent: :destroy
    end
  end
end

