class BodyTrackersController < BodyTrackingPluginController
  before_action :find_project_by_project_id, only: [:index, :defaults]
  before_action :authorize

  def index
  end

  def defaults
    # Units
    available = @project.units.pluck(:shortname)
    defaults = Unit.where(project: nil).map do |u|
      u.attributes.except('id', 'project_id', 'created_at', 'updated_at')
    end
    defaults.delete_if { |u| available.include?(u['shortname']) }
    @project.units.create(defaults)

    new_units = defaults.length
    flash[:notice] = "Loaded #{new_units > 0 ? new_units : "no" } new" \
      " #{'unit'.pluralize(new_units)}"

    # Quantities
    available = @project.quantities.map { |q| [[q.name, q.domain], q] }.to_h
    new_quantities = available.length
    defaults = Quantity.where(project: nil)
    Quantity.each_with_level(defaults) do |q, level|
      unless available.has_key?([q.name, q.domain])
        attrs = q.attributes.except('id', 'project_id', 'parent_id', 'lft', 'rgt',
                                    'created_at', 'updated_at')
        attrs['parent'] = q.parent ? available[[q.parent.name, q.parent.domain]] : nil
        attrs['formula_attributes'] = q.formula ? q.formula.attributes
          .except('id', 'quantity_id', 'created_at', 'updated_at') : {}
        obj = @project.quantities.create(attrs)
        available[[q.name, q.domain]] = obj
      end
    end

    new_quantities = available.length - new_quantities
    flash[:notice] += ", #{new_quantities > 0 ? new_quantities : "no" } new" \
      " #{'quantity'.pluralize(new_quantities)}"

    ncv = @project.nutrients_column_view
    if ncv.quantities.count == 0
      ncv.quantities.append(@project.quantities.roots.first(6))
      ncv.save!
    end

    # Sources
    available = @project.sources.pluck(:name)
    defaults = Source.where(project: nil).map do |s|
      s.attributes.except('id', 'project_id', 'created_at', 'updated_at')
    end
    defaults.delete_if { |s| available.include?(s['name']) }
    @project.sources.create(defaults)

    new_sources = defaults.length
    flash[:notice] += " and #{new_sources > 0 ? new_sources : "no" } new" \
      " #{'source'.pluralize(new_sources)}"

    redirect_to :back
  end
end
