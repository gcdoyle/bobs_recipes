# frozen_string_literal: true

require "yaml"

# Creates recipes from a YAML file (see db/recipes/*.yml for the format).
#
# - Ingredients are matched by name, ignoring case; missing ones are created.
# - Categories are matched the same way and created if missing.
# - Recipes whose name already exists are skipped, so a file can be re-run,
#   unless the entry has `replace: true`, which deletes and re-creates it.
# - Text lines must be strings and ingredient lines may only use qty, measure,
#   ingredient and note. An unquoted ": " or "," in YAML silently turns text
#   into a hash, so this is checked rather than trusted.
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
        validate!(attrs)
        name = attrs.fetch("name")
        if attrs["replace"] && existing.include?(name.downcase)
          Recipe.where("lower(name) = ?", name.downcase).destroy_all
          create_recipe(attrs)
        elsif existing.include?(name.downcase)
          @result.skipped << name
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

  LINE_KEYS = %w[qty measure ingredient note].freeze

  def validate!(attrs)
    name = attrs["name"]
    %w[description directions notes].each do |key|
      Array(attrs[key]).each do |text|
        raise ArgumentError, "#{name}: #{key} line isn't plain text (quote it): #{text.inspect}" unless text.is_a?(String)
      end
    end
    Array(attrs["ingredients"]).each do |line|
      ok = line.is_a?(Hash) && (line.keys - LINE_KEYS).empty? &&
            line.values.all? { |v| v.is_a?(String) || v.is_a?(Numeric) }
      raise ArgumentError, "#{name}: bad ingredient line (quote it): #{line.inspect}" unless ok
    end
  end

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
