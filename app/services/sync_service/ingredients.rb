# frozen_string_literal: true

# Creates ingredients from an Open Food Facts export (see IngredientFeed for
# which entries are kept). Safe to re-run: names already in the database are
# skipped, ignoring case. Everything is created in one transaction.
class SyncService::Ingredients
  DEFAULT_PATH = "ingredients.json"

  def self.call(path: nil, dry_run: false, out: $stdout)
    new(path: path, dry_run: dry_run, out: out).sync
  end

  def initialize(path: nil, dry_run: false, out: $stdout)
    @path = Rails.root.join(path.presence || DEFAULT_PATH)
    @dry_run = dry_run
    @out = out
  end

  # Returns the ingredients created (or that would be created, on a dry run).
  def sync
    feed = IngredientFeed.from_file(@path)
    existing = Ingredient.pluck(:name).to_set { |name| name.downcase }
    fresh = feed.entries.reject { |entry| existing.include?(entry.name.downcase) }

    report(feed, fresh)
    return fresh if @dry_run

    Ingredient.transaction do
      fresh.each { |entry| Ingredient.create!(name: entry.name, url: entry.url) }
    end
    @out.puts "Created #{fresh.size} ingredients."
    fresh
  end

  private

  def report(feed, fresh)
    @out.puts "#{@path.basename}: #{feed.entries.size} usable entries " \
              "(#{feed.entries.count { |e| e.source == :clean }} clean, " \
              "#{feed.entries.count { |e| e.source == :tidied }} tidied from slugs)"
    feed.skipped.each { |reason, count| @out.puts "  skipped #{count} (#{reason.to_s.tr('_', ' ')})" if count.positive? }
    @out.puts "  #{feed.entries.size - fresh.size} already exist; #{fresh.size} to create"
    @out.puts "Dry run: nothing written." if @dry_run
  end
end
