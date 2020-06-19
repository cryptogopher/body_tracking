class BodyTrackersController < ApplicationController
  layout 'body_tracking'
  menu_item :body_trackers

  before_action :find_project_by_project_id, only: [:index, :defaults]
  before_action :authorize

  def index
  end

  def defaults
    failed_objects = []

    # Units
    available_units = @project.units.pluck(:shortname, :id).to_h
    defaults = Unit.where(project: nil).map do |u|
      u.attributes.except('id', 'project_id', 'created_at', 'updated_at')
    end
    defaults.delete_if { |u| available_units.has_key?(u['shortname']) }
    new_units = @project.units.create(defaults).map { |u| [u.shortname, u.id] }.to_h
    available_units.merge(new_units)

    flash[:notice] = "Loaded #{new_units.length > 0 ? new_units.length : "no" } new" \
      " #{'unit'.pluralize(new_units.length)}"

    # Quantities
    available_quantities = Quantity.each_with_path(@project.quantities).map(&:rotate).to_h
    quantities_count = available_quantities.length
    defaults = Quantity.where(project: nil)
    Quantity.each_with_path(defaults) do |q, path|
      unless available_quantities.has_key?(path)
        attrs = q.attributes.except('id', 'project_id', 'parent_id', 'lft', 'rgt',
                                    'created_at', 'updated_at')
        if q.parent
          attrs['parent'] = available_quantities[path.rpartition('::').first]
        end
        if q.formula
          attrs['formula_attributes'] = q.formula.attributes
            .except('id', 'quantity_id', 'unit_id', 'created_at', 'updated_at')
          attrs['formula_attributes']['unit_id'] = available_units[q.formula.unit.shortname]
        end
        available_quantities[path] = @project.quantities.build(attrs)
      end
    end
    Quantity.transaction do
      failed_objects += available_quantities.values.reject { |o| o.persisted? || o.save }
    end

    new_quantities_count = @project.quantities(true).size - quantities_count
    flash[:notice] += ", #{new_quantities_count > 0 ? new_quantities_count : "no" } new" \
      " #{'quantity'.pluralize(new_quantities_count)}"

    if @project.nutrient_quantities.empty?
      @project.nutrient_quantities << @project.quantities.diet.roots.first(6)
    end

    # Sources
    available_sources = @project.sources.pluck(:name, :id).to_h
    defaults = Source.where(project: nil).map do |s|
      s.attributes.except('id', 'project_id', 'created_at', 'updated_at')
    end
    defaults.delete_if { |s| available_sources.has_key?(s['name']) }
    new_sources = @project.sources.create(defaults).map { |s| [s.name, s.id] }.to_h
    available_sources.merge(new_sources)

    flash[:notice] += " and #{new_sources.length > 0 ? new_sources.length : "no" } new" \
      " #{'source'.pluralize(new_sources.length)}"

    if failed_objects.present?
      flash[:notice] += " (loading #{failed_objects.length} objects failed, see errors)"
      flash[:error] = failed_objects.map do |o|
        "<p>#{o.class.name} #{o.name}: #{o.errors.full_messages.join(', ')}</p>"
      end.join.html_safe
    end

    redirect_to :back
  end
end
