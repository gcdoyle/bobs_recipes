require "test_helper"

class SyncIngredientsTest < ActiveSupport::TestCase
  setup do
    @file = Tempfile.new(["ingredients", ".json"])
    @file.write({ tags: [
      { name: "garlic", url: "x" },            # stray lowercase: skipped
      { name: "GARLIC", url: "x" },            # already exists (fixture "Garlic")
      { name: "Pear juice", url: "https://example.com/pear-juice" },
      { name: "hard-salami", url: "https://example.com/hard-salami" }
    ] }.to_json)
    @file.close
  end

  teardown { @file.unlink }

  def sync(**opts)
    SyncService::Ingredients.call(path: @file.path, out: StringIO.new, **opts)
  end

  test "creates new ingredients and skips existing names" do
    assert_difference "Ingredient.count", 2 do
      sync
    end
    assert_equal "https://example.com/hard-salami", Ingredient.find_by!(name: "Hard salami").url
  end

  test "running it again creates nothing" do
    sync
    assert_no_difference("Ingredient.count") { sync }
  end

  test "dry run writes nothing" do
    assert_no_difference("Ingredient.count") { sync(dry_run: true) }
  end
end
