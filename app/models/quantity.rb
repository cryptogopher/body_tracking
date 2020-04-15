class Quantity < ActiveRecord::Base
  enum domain: {
    diet: 0,
    measurement: 1,
    exercise: 2
  }

  acts_as_nested_set dependent: :destroy, scope: :project
  belongs_to :project, required: false
  has_many :nutrients, dependent: :restrict_with_error
  has_many :readouts, dependent: :restrict_with_error
  has_many :exposures, dependent: :destroy

  has_one :formula, inverse_of: :quantity, dependent: :destroy, validate: true
  accepts_nested_attributes_for :formula, allow_destroy: true, reject_if: proc { |attrs|
    attrs['code'].blank?
  }

  validates :name, presence: true, uniqueness: {scope: :project_id}
  validates :domain, inclusion: {in: domains.keys}
  validate if: -> { parent.present? } do
    errors.add(:parent, :parent_domain_mismatch) unless domain == parent.domain
  end

  after_initialize do
    if new_record?
      self.domain ||= :diet
    end
  end

  def movable?(direction)
    case direction
    when :up
      self.left_sibling.present?
    when :down
      self.right_sibling.present?
    when :left
      self.parent.present?
    when :right
      left = self.left_sibling
      left.present? && (left.domain == self.domain)
    else
      false
    end
  end

  def self.filter(project, filters)
    quantities = all

    if filters[:domain].present?
      quantities = quantities.where(domain: domains[filters[:domain]])
    end

    quantities
  end
end
