module MealsHelper
  def meal_links(m)
    link_to(l(:button_edit), edit_meal_path(m),
            {remote: true, class: "icon icon-edit"}) +
    delete_link(meal_path(m), {remote: true, data: {}})
  end

  def display_notes(m)
    content_tag(:span, m.notes) +
    link_to(l(:button_notes), edit_notes_meal_path(m),
            {remote: true, class: "icon icon-wiki-page", style: "float: right"})
  end
end
