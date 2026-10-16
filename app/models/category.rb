class Category < ApplicationRecord
  has_many :recipe_categories, dependent: :destroy
  has_many :recipes, through: :recipe_categories
  
  extend FriendlyId
  friendly_id :name, use: [:slugged, :finders]
  friendly_id :slug_candidates, use: :slugged

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
