module BodyTracking
  module ProjectPatch
    Project.class_eval do
      has_many :units, dependent: :destroy
      has_many :quantities, dependent: :destroy
    end
  end
end

