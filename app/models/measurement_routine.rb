class MeasurementRoutine < ActiveRecord::Base
  belongs_to :project, required: true
  has_many :measurements, -> { order "taken_at DESC" }, inverse_of: :routine,
    foreign_key: 'routine_id', dependent: :restrict_with_error,
    extend: BodyTracking::ItemsWithQuantities
  has_many :readout_columns, as: :column_view, dependent: :destroy,
    class: 'QuantityColumn', extend: BodyTracking::TogglableColumns
  has_many :quantities, -> { order "lft" }, through: :readout_columns

  validates :name, presence: true, uniqueness: {scope: :project_id}
end
