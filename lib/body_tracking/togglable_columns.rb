module BodyTracking::TogglableColumns
  # TODO: enforce 'domain' identity between quantites and receiving collection?
  def toggle!(q)
    column = find_by(quantity: q)
    column ? destroy(column) : create(quantity: q)
  end
end
