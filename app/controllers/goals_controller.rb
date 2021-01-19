class GoalsController < ApplicationController
  include Concerns::Finders

  before_action :find_goal, only: [:show, :edit]
  before_action :authorize

  def show
  end

  def edit
  end
end
