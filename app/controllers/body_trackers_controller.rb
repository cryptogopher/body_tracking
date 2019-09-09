class BodyTrackersController < ApplicationController
  before_action :find_project_by_project_id, only: [:index, :defaults]
  before_action :authorize

  def index
  end

  def defaults
    available = Unit.where(project: @project).pluck(:shortname)
    defaults = Unit.where(project: nil).pluck(:name, :shortname)
    defaults.delete_if { |n, s| available.include?(s) }
    @project.units.create(defaults.map { |n, s| {name: n, shortname: s} })

    new_units = defaults.length
    flash[:notice] = "Loaded #{new_units > 0 ? new_units : "no" } new" \
      " #{'unit'.pluralize(new_units)}"

    available = Quantity.where(project: @project).map { |q| [[q.name, q.domain], q] }.to_h
    new_quantities = available.length
    defaults = Quantity.where(project: nil)
    Quantity.each_with_level(defaults) do |q, level|
      unless available.has_key?([q.name, q.domain])
        obj = @project.quantities.create({
          name: q.name,
          domain: q.domain,
          description: q.description,
          parent: q.parent ? available[[q.parent.name, q.parent.domain]] : nil
        })
        available[[q.name, q.domain]] = obj
      end
    end

    new_quantities = available.length - new_quantities
    flash[:notice] += " and #{new_quantities > 0 ? new_quantities : "no" } new" \
      " #{'quantity'.pluralize(new_quantities)}"

    redirect_to :back
  end
end
