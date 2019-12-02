class Source < ActiveRecord::Base
  belongs_to :project, required: false

  validates :name, presence: true, uniqueness: {scope: :project_id}

  # Has to go before any 'dependent:' association
  before_destroy do
    # FIXME: disallow destruction if any object depends on this quantity
    nil
  end
end
