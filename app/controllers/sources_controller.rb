class SourcesController < ApplicationController
  layout 'body_tracking'
  menu_item :body_trackers

  before_action :find_project_by_project_id, only: [:index, :create]
  before_action :find_source, only: [:destroy]
  before_action :authorize

  def index
    @source = @project.sources.new
    @sources = @project.sources
  end

  def create
    @source = @project.sources.new(source_params)
    if @source.save
      flash[:notice] = 'Created new source'
      redirect_to project_sources_url(@project)
    else
      @sources = @project.sources
      render :index
    end
  end

  def destroy
    if @source.destroy
      flash[:notice] = 'Deleted source'
    end
    redirect_to project_sources_url(@project)
  end

  private

  def source_params
    params.require(:source).permit(
      :name,
      :description
    )
  end

  # :find_* methods are called before :authorize,
  # @project is required for :authorize to succeed
  def find_source
    @source = Source.find(params[:id])
    @project = @source.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
