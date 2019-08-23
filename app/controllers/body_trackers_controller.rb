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

    redirect_to :back
  end
end
