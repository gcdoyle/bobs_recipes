class Ingredient < ApplicationRecord
  has_many :recipe_ingredients, dependent: :restrict_with_error
  has_many :recipes, through: :recipe_ingredients

  has_one_attached :image

  validates :name, presence: true
  validates :name, uniqueness: true

  accepts_nested_attributes_for :recipe_ingredients

  extend FriendlyId
  friendly_id :slug_candidates, use: [:slugged, :finders]

  validates_presence_of :name, :slug

  def slug_candidates
    [
      :name,
      [:name, :id]
    ]
  end

  def should_generate_new_friendly_id?
    name_changed? || slug.blank?
  end

end
