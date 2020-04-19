class IngredientsController < ApplicationController
  include Concerns::Finders

  before_action :find_ingredient, only: [:adjust]
  before_action :authorize

  def adjust
    amount = params[:adjustment].to_i
    @ingredient.amount += amount if @ingredient.amount > -amount
    @ingredient.save
  end
end
