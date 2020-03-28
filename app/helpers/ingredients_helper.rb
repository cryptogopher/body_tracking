module IngredientsHelper
  def quantity_options
    nested_set_options(@project.quantities.diet) do |q|
      raw("#{'&ensp;' * q.level}#{q.name}")
    end
  end

  def toggle_column_options
    disabled = []
    enabled_quantities = @project.nutrient_quantities.to_a
    options = nested_set_options(@project.quantities.diet) do |q|
      disabled << q.id if enabled_quantities.include?(q)
      raw("#{'&ensp;' * q.level}#{q.name}")
    end
    options_for_select(options, disabled: disabled)
  end

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
    Ingredient.groups.map do |k,v|
      [translations[k.to_sym], k]
    end
  end

  def action_links(i)
    link_to(l(:button_edit), edit_ingredient_path(i, view_mode: current_view),
            {remote: true, class: "icon icon-edit"}) +
    delete_link(ingredient_path(i), {remote: true, data: {}})
  end
end
