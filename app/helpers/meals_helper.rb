module MealsHelper
  def action_links(m)
    delete_link(meal_path(m), {remote: true, data: {}}) if m.persisted?
  end
end
