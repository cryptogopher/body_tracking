class Source < ActiveRecord::Base
  belongs_to :project, required: false

  validates :name, presence: true, uniqueness: {scope: :project_id}
end
