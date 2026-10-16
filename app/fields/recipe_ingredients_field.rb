require "administrate/field/base"

# Editable list of a recipe's ingredient lines: add, remove and drag to reorder.
class RecipeIngredientsField < Administrate::Field::Base
  ROW_ATTRIBUTES = %i[id position qty measure ingredient_id note _destroy].freeze

  def self.permitted_attribute(_attr, _options = nil)
    { recipe_ingredients_attributes: ROW_ATTRIBUTES }
  end

  def permitted_attribute
    self.class.permitted_attribute(attribute)
  end

  def ingredient_options
    @ingredient_options ||= Ingredient.order(:name).pluck(:name, :id)
  end

  def lines
    data.includes(:ingredient)
  end

  def to_s
    "#{data.size} ingredients"
  end
end
