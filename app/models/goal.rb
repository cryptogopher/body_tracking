class Goal < ActiveRecord::Base
  belongs_to :project, required: true
  has_many :targets, -> { order "effective_from DESC" }, inverse_of: :goal,
    dependent: :destroy, extend: BodyTracking::ItemsWithQuantities
  has_many :target_exposures, as: :view, dependent: :destroy,
    class_name: 'Exposure', extend: BodyTracking::TogglableExposures
  has_many :quantities, -> { order "lft" }, through: :target_exposures

  validates :target_exposures, presence: true
  validates :is_binding, uniqueness: {scope: :project_id}, if: :is_binding?
  validates :name, presence: true, uniqueness: {scope: :project_id}

  after_initialize do
    if new_record?
      self.is_binding = false if self.is_binding.nil?
    end
  end
end