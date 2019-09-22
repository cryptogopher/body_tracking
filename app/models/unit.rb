class Unit < ActiveRecord::Base
  belongs_to :project, required: false

  validates :shortname, presence: true, uniqueness: {scope: :project_id}
end
