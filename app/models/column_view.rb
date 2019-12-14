class ColumnView < ActiveRecord::Base
  enum domain: Quantity.domains

  belongs_to :project, required: true
  has_and_belongs_to_many :quantities

  validates :name, presence: true, uniqueness: {scope: :domain}
  validates :domain, inclusion: {in: domains.keys}

  # TODO: enforce column_view - quantity 'domain' identity
  def toggle_column!(q)
    column = self.quantities.find(q.id)
    self.quantites.destroy(column)
  rescue ActiveRecord::RecordNotFound
    self.quantities.create!(quantity: q)
  end
end
