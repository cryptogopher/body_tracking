module MealsHelper
  def meal_links(m)
    link_to(l(:button_edit), edit_meal_path(m),
            {remote: true, class: "icon icon-edit"}) +
    delete_link(meal_path(m), {remote: true, data: {}})
  end

  def adjust_ingredient_links(i)
    [-10, -1, 0, 1, 10].map do |v|
      if v != 0
        link_to "%+d" % v, adjust_ingredient_path(i, adjustment: v),
          {remote: true, method: :post, class: "button #{v>0 ? 'green' : 'red'}"}
      else
        yield.to_s
      end
    end.reduce(:+)
  end
end
