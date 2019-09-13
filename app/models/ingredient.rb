class Ingredient < ActiveRecord::Base
  enum group: {
    meat: 0
  }

  belongs_to :project
  has_many :nutrients
  accepts_nested_attributes_for :nutrients

  validates :project, associated: true
  validates :name, presence: true, uniqueness: {scope: :project_id}
  validates :ref_amount, numericality: {greater_than: 0}
  validates :ref_unit, presence: true, associated: true
  validates :group, inclusion: {in: groups.keys}
end
