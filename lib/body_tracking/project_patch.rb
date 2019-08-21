module BodyTracking
  module ProjectPatch
    Project.class_eval do
      has_many :units, dependent: :destroy
    end
  end
end

