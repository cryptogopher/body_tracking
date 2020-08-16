class Goal < ActiveRecord::Base
  belongs_to :project, required: true
  has_many :targets, -> { order "effective_from DESC" }, inverse_of: :goal,
    dependent: :destroy, extend: BodyTracking::ItemsWithQuantities
  has_many :target_exposures, as: :view, dependent: :destroy,
    class_name: 'Exposure', extend: BodyTracking::TogglableExposures
  has_many :quantities, -> { order "lft" }, through: :target_exposures

  validates :target_exposures, presence: true
  validates :name, presence: true, uniqueness: {scope: :project_id}

  def is_binding?
    self == project.goals.binding
  end
end
