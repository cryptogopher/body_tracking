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

    available = Quantity.where(project: @project).map { |q| [[q.name, q.domain], q] }.to_h
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

    redirect_to :back
  end
end
