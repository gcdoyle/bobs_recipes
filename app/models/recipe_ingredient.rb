class RecipeIngredient < ApplicationRecord
  MEASURES = %w[
    cup tsp tbsp oz lb qt pt gal L ML clove head bunch stalk sprig rib leaf
    part pinch dash rack slice splash squirt bottle handful drizzle
  ].freeze

  belongs_to :recipe
  belongs_to :ingredient
end