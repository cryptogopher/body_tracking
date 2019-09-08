class Quantity < ActiveRecord::Base
  acts_as_nested_set dependent: :nullify, scope: :project

  enum domain: {
    diet: 0,
    measurement: 1,
    exercise: 2
  }

  belongs_to :project

  validates :project, associated: true
  validates :name, presence: true, uniqueness: {scope: :project_id}
  validates :domain, inclusion: {in: domains.keys}
  validates :parent, associated: true
  validate if: -> { parent.present? } do
    errors.add(:parent, :parent_domain_mismatch) unless domain == parent.domain
  end
end
