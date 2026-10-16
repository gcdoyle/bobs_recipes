# frozen_string_literal: true

require "json"

# Reads an Open Food Facts ingredient export ({"tags": [{"name", "url"}, ...]})
# and picks the entries worth importing:
#
# - properly written names ("Pear juice") are kept as they are
# - slug-style names ("hard-salami") are tidied into "Hard salami"
# - other-language entries ("de:sucre") and stray lowercase words ("approx")
#   are skipped
#
# When a tidied slug and a clean name mean the same thing, the clean one wins.
# Plain Ruby, so it can be tried outside Rails.
class IngredientFeed
  Entry = Struct.new(:name, :url, :source, keyword_init: true)

  FOREIGN = /\A[a-z]{2}:/
  SLUG = /\A[[:lower:][:digit:]]+(?:-[[:lower:][:digit:]]+)+\z/

  def self.from_file(path)
    new(File.read(path))
  end

  def self.tidy(slug)
    words = slug.tr("-", " ")
    words[0].upcase + words[1..]
  end

  attr_reader :skipped

  def initialize(json)
    @tags = JSON.parse(json).fetch("tags")
    @skipped = Hash.new(0)
  end

  def entries
    @entries ||= begin
      candidates = @tags.filter_map { |tag| entry_for(tag) }
      unique = candidates.sort_by { |e| e.source == :clean ? 0 : 1 }
                         .uniq { |e| e.name.downcase }
      @skipped[:duplicate] += candidates.size - unique.size
      unique.sort_by { |e| e.name.downcase }
    end
  end

  private

  def entry_for(tag)
    name = tag["name"].to_s.strip
    url = tag["url"].to_s.strip
    url = nil if url.empty?

    case reason_to_skip(name)
    when nil
      if name.match?(SLUG)
        Entry.new(name: self.class.tidy(name), url: url, source: :tidied)
      else
        Entry.new(name: name, url: url, source: :clean)
      end
    else
      @skipped[reason_to_skip(name)] += 1
      nil
    end
  end

  def reason_to_skip(name)
    if name.empty? then :blank
    elsif name.match?(FOREIGN) then :other_language
    elsif name.match?(SLUG) || name.match?(/[[:upper:]]/) then nil
    else :stray_lowercase
    end
  end
end
