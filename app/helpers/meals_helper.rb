module MealsHelper
  def meal_links(m)
    delete_link(meal_path(m), {remote: true, data: {}}) if m.persisted?
  end
  def adjust_ingredient_link(i, adjustment)
    link_to "%+d" % adjustment, adjust_ingredient_path(i, adjustment: adjustment),
      {remote: true, method: :post}
  end
end
