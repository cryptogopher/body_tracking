class Quantity < ActiveRecord::Base
  enum domain: {
    diet: 0,
    measurement: 1,
    exercise: 2
  }

  belongs_to :project

  validates :project, associated: true
  validates :name, presence: true, uniqueness: {scope: :project_id}
  validates :domain, inclusion: {in: domains.keys}
end
