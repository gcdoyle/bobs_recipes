module RecipesHelper
  FRACTIONS = {
    Rational(1, 8) => "1/8", Rational(1, 4) => "1/4", Rational(1, 3) => "1/3",
    Rational(3, 8) => "3/8", Rational(1, 2) => "1/2", Rational(5, 8) => "5/8",
    Rational(2, 3) => "2/3", Rational(3, 4) => "3/4", Rational(7, 8) => "7/8"
  }.freeze

  # 4.5 -> "4 1/2", 0.13 -> "1/8", 2.0 -> "2"; other values print as decimals.
  def format_qty(qty)
    return "" if qty.blank?

    whole = qty.floor
    part = qty - whole
    return whole.to_s if part.zero?

    fraction, label = FRACTIONS.min_by { |value, _| (value - part).abs }
    return strip_trailing_zero(qty) if (fraction - part).abs > 0.01

    whole.zero? ? label : "#{whole} #{label}"
  end

  # An ingredient that is itself a recipe links to that recipe; otherwise it
  # links to its "more about" url if it has one, or is plain text.
  def ingredient_name_link(ingredient, sub_recipes)
    if (recipe = sub_recipes[ingredient.name.downcase])
      link_to ingredient.name, recipe_path(recipe), class: "sub-recipe-link",
              title: "See the #{recipe.name} recipe"
    elsif ingredient.url.present?
      link_to ingredient.name, ingredient.url
    else
      ingredient.name
    end
  end

  def strip_trailing_zero(n)
    n.to_s.sub(/\.?0+$/, '')
  end
end
