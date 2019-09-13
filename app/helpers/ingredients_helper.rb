module IngredientsHelper
  def quantity_options
    nested_set_options(@project.quantities.diet) do |q|
      raw("#{'&ensp;' * q.level}#{q.name}")
    end
  end

  def unit_options
    @project.units.map do |u|
      [u.shortname, u.id]
    end
  end

  def group_options
    translations = t('.groups')
    Ingredient.groups.map do |k,v|
      [translations[k.to_sym], k]
    end
  end
end
