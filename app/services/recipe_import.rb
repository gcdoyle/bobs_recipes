# frozen_string_literal: true

require "yaml"

# Creates recipes from a YAML file (see db/recipes/*.yml for the format).
#
# - Ingredients are matched by name, ignoring case; missing ones are created.
# - Categories are matched the same way and created if missing.
# - Recipes whose name already exists are skipped, so a file can be re-run.
# - Everything happens in one transaction; a dry run rolls it back at the end,
#   so it checks the whole file without writing anything.
class RecipeImport
  Result = Struct.new(:created, :skipped, :new_ingredients, :new_categories, keyword_init: true)

  def self.call(path:, dry_run: false, out: $stdout)
    new(path: path, dry_run: dry_run, out: out).run
  end

  def initialize(path:, dry_run: false, out: $stdout)
    @path = Rails.root.join(path.to_s)
    @dry_run = dry_run
    @out = out
  end

  def run
    data = YAML.safe_load_file(@path)
    @result = Result.new(created: [], skipped: [], new_ingredients: [], new_categories: [])
    @ingredients = Ingredient.all.index_by { |i| i.name.downcase }
    @categories = Category.all.index_by { |c| c.name.downcase }
    existing = Recipe.pluck(:name).to_set { |name| name.downcase }

    Recipe.transaction do
      data.fetch("recipes").each do |attrs|
        if existing.include?(attrs.fetch("name").downcase)
          @result.skipped << attrs["name"]
        else
          create_recipe(attrs)
        end
      end
      raise ActiveRecord::Rollback if @dry_run
    end

    report
    @result
  end

  # "4 1/2" -> 4.5, "1/8" -> 0.125, 2 -> 2
  def self.parse_qty(value)
    return if value.blank?
    return value if value.is_a?(Numeric)

    value.to_s.split.sum { |part| Rational(part) }.to_d(4)
  end

  private

  def create_recipe(attrs)
    recipe = Recipe.new(
      name: attrs.fetch("name"),
      prep_time: attrs["prep_time"],
      cooking_time: attrs["cooking_time"],
      servings: attrs["servings"],
      description: paragraphs(attrs["description"]),
      directions: directions(attrs["directions"], attrs["notes"])
    )
    recipe.categories = Array(attrs["categories"]).map { |name| category(name) }

    attrs.fetch("ingredients").each_with_index do |line, i|
      measure = line["measure"].presence
      if measure && !RecipeIngredient::MEASURES.include?(measure)
        raise ArgumentError, "#{recipe.name}: unknown measure #{measure.inspect}"
      end

      recipe.recipe_ingredients.build(
        ingredient: ingredient(line.fetch("ingredient")),
        qty: self.class.parse_qty(line["qty"]),
        measure: measure,
        note: line["note"].presence,
        position: i + 1
      )
    end

    recipe.save!
    @result.created << recipe.name
  end

  def ingredient(name)
    @ingredients[name.downcase] ||= Ingredient.create!(name: name).tap { |i| @result.new_ingredients << i.name }
  end

  def category(name)
    @categories[name.downcase] ||= Category.create!(name: name).tap { |c| @result.new_categories << c.name }
  end

  def paragraphs(texts)
    Array(texts).map { |text| "<p>#{ERB::Util.html_escape(text)}</p>" }.join
  end

  def directions(steps, notes)
    items = Array(steps).map { |step| "<li>#{ERB::Util.html_escape(step)}</li>" }.join
    (items.present? ? "<ol>#{items}</ol>" : "") + paragraphs(notes)
  end

  def report
    @out.puts "#{@path.basename}: #{@result.created.size} recipes #{@dry_run ? 'would be created' : 'created'}" \
              "#{", #{@result.skipped.size} skipped (already exist)" if @result.skipped.any?}"
    @out.puts "  new categories: #{@result.new_categories.join(', ')}" if @result.new_categories.any?
    if @result.new_ingredients.any?
      @out.puts "  new ingredients (#{@result.new_ingredients.size}): #{@result.new_ingredients.sort.join(', ')}"
    end
    @out.puts "Dry run: nothing written." if @dry_run
  end
end
