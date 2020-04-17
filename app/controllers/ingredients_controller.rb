class IngredientsController < ApplicationController
  include Concerns::Finders

  before_action :find_ingredient, only: [:adjust]
  before_action :authorize

  def adjust
    params.require(:ingredient).permit(:adjustment)
  end
end
