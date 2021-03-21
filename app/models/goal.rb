class Goal < ActiveRecord::Base
  belongs_to :project, required: true
  has_many :targets, -> { order effective_from: :desc }, inverse_of: :goal,
    dependent: :destroy, extend: BodyTracking::ItemsWithQuantities
  has_many :exposures, as: :view, dependent: :destroy,
    class_name: 'Exposure', extend: BodyTracking::TogglableExposures
  has_many :quantities, -> { order "lft" }, through: :exposures

  accepts_nested_attributes_for :targets, allow_destroy: true
  validates :is_binding, uniqueness: {scope: :project_id}, if: :is_binding?
  validates :name, presence: true, uniqueness: {scope: :project_id},
    exclusion: {in: [I18n.t('goals.binding.name')], unless: :is_binding?}

  after_initialize do
    if new_record?
      self.is_binding = false if self.is_binding.nil?
      self.targets.new if !self.is_binding && self.targets.empty?
    end
  end

  before_save do
    quantities << targets.map(&:quantity)[0..5] if exposures.empty?
  end

  before_destroy prepend: true do
    !is_binding?
  end
end
