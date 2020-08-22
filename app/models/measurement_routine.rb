class MeasurementRoutine < ActiveRecord::Base
  belongs_to :project, required: true
  has_many :measurements, -> { order "taken_at DESC" }, inverse_of: :routine,
    foreign_key: 'routine_id', dependent: :restrict_with_error,
    extend: BodyTracking::ItemsWithQuantities
  has_many :readout_exposures, as: :view, dependent: :destroy,
    class_name: 'Exposure', extend: BodyTracking::TogglableExposures
  has_many :quantities, -> { order "lft" }, through: :readout_exposures

  # TODO: require readout_exposures to be present
  validates :name, presence: true, uniqueness: {scope: :project_id}
end
