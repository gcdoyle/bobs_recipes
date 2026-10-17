class RecipesController < ApplicationController
  before_action :set_recipe, only: %i[ show ]
  include SetInstance

  # GET /recipes or /recipes.json
  def index
    hidden = Recipe.joins(:categories).where(categories: { name: "chris" }).select(:id)
    @recipes = Recipe.where.not(id: hidden).with_attached_image.order(:name)
  end

  # GET /recipes/1 or /recipes/1.json
  def show
    @lines = @recipe.recipe_ingredients.includes(:ingredient).to_a
    @sub_recipes = Recipe.matching_ingredients(@lines.map(&:ingredient), except: @recipe)
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_recipe
      @recipe = find_instance
    end

    # Only allow a list of trusted parameters through.
    # def recipe_params
    #   params.require(:recipe).permit(:title, :ingredient_id, recipe_ingredient_attributes: [:qty, :id, :recipe_id, :ingredient_id])
    # end
end
