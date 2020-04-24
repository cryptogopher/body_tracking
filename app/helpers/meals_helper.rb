module MealsHelper
  def meal_links(m)
    link_to(l(:button_edit), edit_meal_path(m),
            {remote: true, class: "icon icon-edit"}) +
    delete_link(meal_path(m), {remote: true, data: {}})
  end

  def adjustment_buttons(i)
    {'- -' => -10, '-' => -1, '+' => 1, '++' => 10}.map do |text, value|
      link_to text, adjust_ingredient_path(i, adjustment: value),
        {remote: true, method: :post, class: "button #{value>0 ? 'green' : 'red'}"}
    end.reduce(&:+)
  end

  def notes(m)
    content_tag(:span, m.notes)
  end
end
