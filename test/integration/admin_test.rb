require "test_helper"

class AdminTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "anonymous visitors are sent to sign in" do
    get admin_recipes_path
    assert_redirected_to new_user_session_path
  end

  test "signed-in non-admins are sent home" do
    sign_in users(:cook)
    get admin_recipes_path
    assert_redirected_to root_url
  end

  test "admin pages load" do
    sign_in users(:admin)
    get admin_recipes_path
    assert_response :success
    get edit_admin_recipe_path(recipes(:garlic_soup))
    assert_response :success
    get new_admin_recipe_path
    assert_response :success
    get admin_ingredients_path
    assert_response :success
  end

  test "admin creates a recipe with ingredients in form order" do
    sign_in users(:admin)
    assert_difference "Recipe.count", 1 do
      post admin_recipes_path, params: { recipe: {
        name: "Onion Tart",
        category_ids: [categories(:soups).id],
        recipe_ingredients_attributes: {
          "0" => { ingredient_id: ingredients(:onion).id, qty: "2", measure: "cup" },
          "1" => { ingredient_id: ingredients(:salt).id, qty: "1", measure: "tsp" }
        }
      } }
    end
    recipe = Recipe.find_by!(name: "Onion Tart")
    assert_equal %w[Onion Salt], recipe.recipe_ingredients.map { |ri| ri.ingredient.name }
    assert_equal [1, 2], recipe.recipe_ingredients.map(&:position)
    assert_equal [categories(:soups)], recipe.categories.to_a
  end

  test "typing a position moves an ingredient" do
    sign_in users(:admin)
    soup = recipes(:garlic_soup)
    patch admin_recipe_path(soup), params: { recipe: {
      recipe_ingredients_attributes: {
        "0" => { id: recipe_ingredients(:soup_onion).id, position: "1" }
      }
    } }
    assert_equal %w[Onion Garlic], soup.reload.recipe_ingredients.map { |ri| ri.ingredient.name }
    assert_equal [1, 2], soup.recipe_ingredients.map(&:position)
  end

  test "admin show page lists ingredients and loads the custom admin assets" do
    sign_in users(:admin)
    get admin_recipe_path(recipes(:garlic_soup))
    assert_response :success
    assert_select ".attribute-data--recipe-ingredients-field li", 2
    assert_select "script[src*='admin/custom']"
    assert_select "link[href*='admin/custom']"
  end

  test "edit form renders ingredient rows, a row template and tabs" do
    sign_in users(:admin)
    get edit_admin_recipe_path(recipes(:garlic_soup))
    assert_select "[data-recipe-ingredients] tbody [data-row]", 2
    assert_select "template[data-row-template]"
    assert_select "[data-admin-tab]", 4
  end

  test "a blank added row is ignored and a checked row is removed" do
    sign_in users(:admin)
    soup = recipes(:garlic_soup)
    patch admin_recipe_path(soup), params: { recipe: {
      recipe_ingredients_attributes: {
        "0" => { id: recipe_ingredients(:soup_garlic).id, _destroy: "1" },
        "1" => { id: recipe_ingredients(:soup_onion).id, position: "1" },
        "1700000000000" => { position: "3", qty: "", measure: "", ingredient_id: "", note: "" }
      }
    } }
    assert_redirected_to admin_recipe_path(soup.reload)
    assert_equal %w[Onion], soup.recipe_ingredients.map { |ri| ri.ingredient.name }
    assert_equal [1], soup.recipe_ingredients.map(&:position)
  end

  test "an ingredient used by a recipe can't be deleted" do
    sign_in users(:admin)
    assert_no_difference "Ingredient.count" do
      delete admin_ingredient_path(ingredients(:garlic))
    end
  end
end
