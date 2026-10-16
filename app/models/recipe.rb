class Recipe < ApplicationRecord
  has_many :recipe_ingredients, -> { order(:position, :id) }, inverse_of: :recipe, dependent: :destroy
  has_many :ingredients, through: :recipe_ingredients

  has_many :recipe_categories, dependent: :destroy
  has_many :categories, through: :recipe_categories

  has_one_attached :image

  has_rich_text :description
  has_rich_text :directions

  # A new row with no ingredient picked is an unused blank row; skip it.
  accepts_nested_attributes_for(
    :recipe_ingredients,
    reject_if: ->(attrs) { attrs["id"].blank? && attrs["ingredient_id"].blank? },
    allow_destroy: true
  )
  
  extend FriendlyId
  friendly_id :slug_candidates, use: [:slugged, :finders]

  validates_presence_of :name, :slug

  before_save :number_ingredients

  # Renumber ingredients 1..n, honoring any position typed on the form.
  # A row whose number was just edited wins a tie, so typing 1 moves it to
  # the top. Rows without a position (new ones) keep their form order at the end.
  def number_ingredients
    rows = recipe_ingredients.reject(&:marked_for_destruction?)
    rows.each_with_index
        .sort_by { |ri, i| [ri.position || Float::INFINITY, ri.position_changed? ? 0 : 1, i] }
        .each.with_index(1) { |(ri, _), n| ri.position = n }
  end

  def slug_candidates
    [
      :name,
      [:name, :id]
    ]
  end

  def should_generate_new_friendly_id?
    name_changed? || slug.blank?
  end
    
  def self.search(q)
    return none if q.blank?

    term = "%#{sanitize_sql_like(q.to_s.strip.downcase)}%"
    left_joins(:ingredients)
      .where("lower(recipes.name) LIKE :t OR lower(ingredients.name) LIKE :t", t: term)
      .distinct
      .with_attached_image
      .order(:name)
  end
end
