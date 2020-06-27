module FoodsHelper
  def visibility_options(selected)
    options = [["visible", 1], ["hidden", 0]]
    options_for_select(options, selected)
  end

  def source_options
    @project.sources.map do |s|
      [s.name, s.id]
    end
  end

  def group_options
    translations = t('.groups')
    Food.groups.map do |k,v|
      [translations[k.to_sym], k]
    end
  end

  def action_links(f, view)
    link_to(l(:button_edit), edit_food_path(f, view: view),
            {remote: true, class: "icon icon-edit"}) +
    delete_link(food_path(f), {remote: true, data: {}})
  end
end
