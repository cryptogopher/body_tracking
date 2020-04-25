module BodyTracking::TogglableExposures
  # TODO: enforce 'domain' identity between quantites and receiving collection?
  def toggle!(q)
    exposure = find_by(quantity: q)
    exposure ? destroy(exposure) : create(quantity: q)
  end
end
