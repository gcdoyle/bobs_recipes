class IngredientsController < ApplicationController
  before_action :set_ingredient, only: %i[ show ]
  include SetInstance

  # GET /ingredients or /ingredients.json
  def index
    @ingredients = Ingredient.all.order(:name)
  end

  # GET /ingredients/1 or /ingredients/1.json
  def show
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ingredient
      @ingredient = find_instance
    end

end
