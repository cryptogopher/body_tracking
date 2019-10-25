class Quantity < ActiveRecord::Base
  enum domain: {
    diet: 0,
    measurement: 1,
    exercise: 2
  }

  acts_as_nested_set dependent: :destroy, scope: :project
  belongs_to :project, required: false

  validates :name, presence: true, uniqueness: {scope: :project_id}
  validates :domain, inclusion: {in: domains.keys}
  validate if: -> { parent.present? } do
    errors.add(:parent, :parent_domain_mismatch) unless domain == parent.domain
  end

  after_initialize do
    if new_record?
      self.primary = false if self.primary.nil?
    end
  end
end
