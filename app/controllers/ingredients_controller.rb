class IngredientsController < ApplicationController
  include Concerns::Finders

  before_action :authorize
end
