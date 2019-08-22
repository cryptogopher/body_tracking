class Unit < ActiveRecord::Base
  belongs_to :project

  validates :project, associated: true
  validates :shortname, presence: true, uniqueness: {scope: :project_id}
end
