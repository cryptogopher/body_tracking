class Unit < ActiveRecord::Base
  belongs_to :project

  validates :project, associated: true
  validates :name, :shortname, presence: true, uniqueness: true
end
