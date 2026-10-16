require "test_helper"

class PublicPagesTest < ActionDispatch::IntegrationTest
  test "home page shows categories but not the hidden one" do
    get root_path
    assert_response :success
    assert_select "h4 a", text: "Soups"
    assert_select "h4 a", text: "chris", count: 0
  end

  test "layout loads Bootstrap and the site stylesheet" do
    get root_path
    assert_select "link[rel=stylesheet][href*='bootstrap.min']"
    assert_select "link[rel=stylesheet][href*='recipes']"
  end

  test "category page lists its recipes" do
    get category_path(categories(:soups))
    assert_response :success
    assert_select "h1", "Soups"
    assert_select "h4 a", text: "Roasted Garlic Soup"
  end

  test "all-recipes page leaves out the hidden category" do
    get recipes_path
    assert_response :success
    assert_select "h4 a", text: "Roasted Garlic Soup"
    assert_select "h4 a", text: "Secret Chili", count: 0
  end

  test "recipe page lists ingredients in position order" do
    get recipe_path(recipes(:garlic_soup))
    assert_response :success
    items = css_select(".recipe ul.list-unstyled li").map { |li| li.text.squish }
    assert_match(/Garlic/, items[0])
    assert_match(/Onion/, items[1])
  end

  test "ingredient pages load" do
    get ingredients_path
    assert_response :success
    get ingredient_path(ingredients(:garlic))
    assert_response :success
    assert_select "h1", "Garlic"
    assert_select "a", text: "Roasted Garlic Soup"
  end

  test "search matches recipe names regardless of case" do
    get search_path(q: "GARLIC")
    assert_response :success
    assert_select "#search-results a", text: "Roasted Garlic Soup"
  end

  test "search matches ingredient names" do
    get search_path(q: "onion")
    assert_response :success
    assert_select "#search-results a", text: "Roasted Garlic Soup"
  end

  test "blank search goes home" do
    get search_path(q: "")
    assert_redirected_to root_path
  end
end
