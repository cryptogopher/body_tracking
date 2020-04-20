module MealsHelper
  def meal_links(m)
    link_to(l(:button_edit), edit_meal_path(m),
            {remote: true, class: "icon icon-edit"}) +
    delete_link(meal_path(m), {remote: true, data: {}})
  end

  def adjust_ingredient_links(i)
    {'- -' => -10, '-' => -1, nil => 0, '+' => 1, '++' => 10}.map do |text, value|
      if text
        link_to text, adjust_ingredient_path(i, adjustment: value),
          {remote: true, method: :post, class: "button #{value>0 ? 'green' : 'red'}"}
      else
        yield.to_s
      end
    end.reduce(:+)
  end

  def display_notes(m)
    content_tag(:span, m.notes) +
    link_to(l(:button_notes), edit_notes_meal_path(m),
            {remote: true, class: "icon icon-wiki-page", style: "float: right"})
  end
end
