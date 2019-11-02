module IngredientsHelper
  def quantity_options
    nested_set_options(@project.quantities.diet) do |q|
      raw("#{'&ensp;' * q.level}#{q.name}")
    end
  end

  def nutrient_column_options
    disabled = []
    options = nested_set_options(@project.quantities.diet) do |q|
      disabled << q.id if q.primary
      raw("#{'&ensp;' * q.level}#{q.name}")
    end
    options_for_select(options, disabled: disabled)
  end

  def visibility_options(selected)
    options = [["all", nil], ["visible", 1], ["hidden", 0]]
    options_for_select(options, selected)
  end

  def unit_options
    @project.units.map do |u|
      [u.shortname, u.id]
    end
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
end
