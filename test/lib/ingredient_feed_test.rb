require "test_helper"

class IngredientFeedTest < ActiveSupport::TestCase
  def feed(*names)
    IngredientFeed.new({ tags: names.map { |n| { name: n, url: "https://example.com/#{n}" } } }.to_json)
  end

  test "keeps clean names and tidies slugs" do
    assert_equal ["Hard salami", "Pear juice"], feed("Pear juice", "hard-salami").entries.map(&:name)
  end

  test "skips other-language entries and stray lowercase words" do
    f = feed("de:sucre", "approx", "Leek")
    assert_equal ["Leek"], f.entries.map(&:name)
    assert_equal 1, f.skipped[:other_language]
    assert_equal 1, f.skipped[:stray_lowercase]
  end

  test "skips label fragments that start with a joining word" do
    f = feed("and-annatto", "to-preserve-freshness", "With other natural flavouring", "Annatto", "tomato-paste")
    assert_equal ["Annatto", "Tomato paste"], f.entries.map(&:name)
    assert_equal 3, f.skipped[:label_fragment]
  end

  test "a clean name wins over a tidied slug that means the same thing" do
    entries = feed("salad-dressing", "Salad dressing").entries
    assert_equal 1, entries.size
    assert_equal :clean, entries.first.source
  end
end
