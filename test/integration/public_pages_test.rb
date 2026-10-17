require "test_helper"

class PublicPagesTest < ActionDispatch::IntegrationTest
  test "home page shows categories but not the hidden one" do
    get root_path
    assert_response :success
    assert_select "h4 a", text: "Soups"
    assert_select "h4 a", text: "chris", count: 0
  end

  test "layout loads the compiled stylesheet and the importmap with Bootstrap" do
    get root_path
    assert_select "link[rel=stylesheet][href*='application']"
    assert_select "script[type=importmap]", text: /bootstrap/
    assert_select "button.navbar-toggler[data-bs-target='#site-nav-menu']"
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

  test "an ingredient that is also a recipe links to that recipe" do
    sauce = Ingredient.create!(name: "roasted garlic soup") # case differs on purpose
    pasta = Recipe.create!(name: "Pasta with Soup Sauce")
    pasta.recipe_ingredients.create!(ingredient: sauce, qty: 1, measure: "cup")

    get recipe_path(pasta)
    assert_select ".recipe a.sub-recipe-link[href=?]", recipe_path(recipes(:garlic_soup)),
                  text: "roasted garlic soup"
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

  test "every page has the main navigation with the current section marked" do
    get recipes_path
    assert_select "nav.site-nav a", text: "Categories"
    assert_select "nav.site-nav a", text: "Ingredients"
    assert_select "nav.site-nav a.is-active", text: "All Recipes"
    assert_select "nav.site-nav form#search-block input[name=q]"
    assert_select "nav.site-nav a", text: "Admin", count: 0
    assert_select "nav.site-nav a", text: "Sign in", count: 0
    assert_select "nav.site-nav button", text: "Sign out", count: 0
  end

  test "recipe page links back to its category" do
    get recipe_path(recipes(:garlic_soup))
    assert_select ".breadcrumbs a", text: "Categories"
    assert_select ".breadcrumbs a[href=?]", category_path(categories(:soups)), text: "Soups"
    assert_select ".filed-under a", text: "Soups"
  end

  test "long lists get an A-Z jump bar" do
    get recipes_path
    assert_select ".letter-bar a[href='#letter-R']", text: "R"
    assert_select "h2#letter-R"
    get ingredients_path
    assert_select ".letter-bar a[href='#letter-G']", text: "G"
  end
end
