class SourcesController < ApplicationController
  before_action :find_project_by_project_id, only: [:index, :create]
  before_action :find_source, only: [:destroy]
  before_action :authorize

  def index
    @source = @project.sources.new
    @sources = @project.sources
  end

  def create
  end

  def destroy
  end
end
