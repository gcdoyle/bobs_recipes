
class CategoriesController < ApplicationController
  before_action :set_category, only: :show
  include SetInstance

  def index
    @categories = Category.where.not(name: :chris).order(:name)
    @cards = []
    card = {}
    @categories.each do |category|
      recipe = Recipe.joins(:categories).where( categories: { name: category.name }).sample
        @cards << { category.name.to_sym => recipe } if recipe.present?
        card.clear
    end
  end

  def show
    @recipes = @category.recipes.with_attached_image.order(:name)
  end


  private
    def set_category
      @category = find_instance
    end

    def category_params
      params.require(:category).permit(:name)
    end
end