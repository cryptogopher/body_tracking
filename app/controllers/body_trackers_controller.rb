class BodyTrackersController < ApplicationController
  before_action :find_project_by_project_id, only: [:index, :defaults]
  before_action :authorize

  def index
  end

  def defaults
    # Units
    available = @project.units.pluck(:shortname)
    defaults = Unit.where(project: nil).pluck(:name, :shortname)
    defaults.delete_if { |n, s| available.include?(s) }
    @project.units.create(defaults.map { |n, s| {name: n, shortname: s} })

    new_units = defaults.length
    flash[:notice] = "Loaded #{new_units > 0 ? new_units : "no" } new" \
      " #{'unit'.pluralize(new_units)}"

    # Quantities
    available = @project.quantities.map { |q| [[q.name, q.domain], q] }.to_h
    new_quantities = available.length
    defaults = Quantity.where(project: nil)
    Quantity.each_with_level(defaults) do |q, level|
      unless available.has_key?([q.name, q.domain])
        obj = @project.quantities.create({
          domain: q.domain,
          parent: q.parent ? available[[q.parent.name, q.parent.domain]] : nil,
          name: q.name,
          description: q.description,
          displayed: q.displayed
        })
        available[[q.name, q.domain]] = obj
      end
    end

    new_quantities = available.length - new_quantities
    flash[:notice] += ", #{new_quantities > 0 ? new_quantities : "no" } new" \
      " #{'quantity'.pluralize(new_quantities)}"

    # Sources
    available = @project.sources.pluck(:name)
    defaults = Source.where(project: nil).pluck(:name, :description)
    defaults.delete_if { |n, d| available.include?(n) }
    @project.sources.create(defaults.map { |n, d| {name: n, description: d} })

    new_sources = defaults.length
    flash[:notice] += " and #{new_sources > 0 ? new_sources : "no" } new" \
      " #{'source'.pluralize(new_sources)}"

    redirect_to :back
  end
end
