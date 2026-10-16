require "test_helper"

class RecipeTest < ActiveSupport::TestCase
  test "blank search returns nothing" do
    assert_empty Recipe.search("")
    assert_empty Recipe.search(nil)
  end

  test "a recipe matching by name and ingredient appears once" do
    assert_equal [recipes(:garlic_soup)], Recipe.search("garlic").to_a
  end

  test "search treats % and _ literally" do
    assert_empty Recipe.search("%")
  end

  test "destroying a recipe removes its ingredient lines and category tags" do
    soup = recipes(:garlic_soup)
    assert_difference -> { RecipeIngredient.count } => -2, -> { RecipeCategory.count } => -1 do
      soup.destroy
    end
  end
end
