class Goal < ActiveRecord::Base
  belongs_to :project, required: true
  has_many :targets, inverse_of: :goal, dependent: :destroy

  validates :name, presence: true, uniqueness: {scope: :project_id}

  def is_binding?
    self == project.goals.binding
  end
end
