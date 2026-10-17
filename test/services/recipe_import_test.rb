require "test_helper"

class RecipeImportTest < ActiveSupport::TestCase
  YAML_DOC = <<~YAML
    recipes:
      - name: Garlic Noodles
        categories: [Asian, soups]
        prep_time: 5
        servings: 2
        description: ["Quick & easy."]
        ingredients:
          - { qty: "4 1/2", measure: oz, ingredient: Soba noodles }
          - { qty: 2, measure: clove, ingredient: GARLIC, note: minced }
          - { ingredient: Salt, note: to taste }
        directions:
          - Boil the noodles.
          - Toss with garlic.
      - name: Roasted Garlic Soup
        ingredients: []
  YAML

  setup do
    @file = Tempfile.new(["recipes", ".yml"])
    @file.write(YAML_DOC)
    @file.close
  end

  teardown { @file.unlink }

  def import(**opts)
    RecipeImport.call(path: @file.path, out: StringIO.new, **opts)
  end

  test "creates recipes, reusing existing ingredients and categories" do
    result = nil
    # Garlic and Salt exist as fixtures; only Soba noodles is new.
    assert_difference -> { Recipe.count } => 1, -> { Ingredient.count } => 1, -> { Category.count } => 1 do
      result = import
    end
    assert_equal ["Roasted Garlic Soup"], result.skipped
    assert_equal ["Soba noodles"], result.new_ingredients
    assert_equal ["Asian"], result.new_categories

    recipe = Recipe.find_by!(name: "Garlic Noodles")
    lines = recipe.recipe_ingredients.includes(:ingredient)
    assert_equal ["Soba noodles", "Garlic", "Salt"], lines.map { |l| l.ingredient.name }
    assert_equal [1, 2, 3], lines.map(&:position)
    assert_equal BigDecimal("4.5"), lines.first.qty
    assert_equal ingredients(:garlic), lines.second.ingredient
    assert_includes recipe.directions.to_s, "<li>Toss with garlic.</li>"
    assert_includes recipe.description.to_s, "Quick &amp; easy."
    assert_equal [categories(:soups), Category.find_by!(name: "Asian")].to_set, recipe.categories.to_set
  end

  test "dry run writes nothing" do
    assert_no_difference(-> { Recipe.count }, -> { Ingredient.count }) { import(dry_run: true) }
  end

  test "an unknown measure stops the whole import" do
    File.write(@file.path, YAML_DOC.sub("measure: oz", "measure: smidgen"))
    assert_raises(ArgumentError) { import }
    assert_nil Recipe.find_by(name: "Garlic Noodles")
  end

  test "the Asian stir fry file is valid" do
    result = RecipeImport.call(path: "db/recipes/asian_stir_fry.yml", dry_run: true, out: StringIO.new)
    assert_equal 13, result.created.size
  end

  test "unquoted colons and commas in text are rejected" do
    File.write(@file.path, YAML_DOC.sub("- Boil the noodles.", "- Tip: boil the noodles."))
    error = assert_raises(ArgumentError) { import }
    assert_match(/Garlic Noodles: directions line/, error.message)

    File.write(@file.path, YAML_DOC.sub("note: minced }", "note: minced, or sliced }"))
    error = assert_raises(ArgumentError) { import }
    assert_match(/bad ingredient line/, error.message)
  end

  test "replace: true re-creates an existing recipe" do
    recipe = Recipe.find_by!(name: "Roasted Garlic Soup")
    File.write(@file.path, YAML_DOC.sub("  - name: Roasted Garlic Soup\n", "  - name: Roasted Garlic Soup\n    replace: true\n"))
    result = import
    assert_includes result.created, "Roasted Garlic Soup"
    assert_not Recipe.exists?(recipe.id)
    assert_equal 1, Recipe.where(name: "Roasted Garlic Soup").count
  end
end
