module Admin
  class RecipesController < Admin::ApplicationController
    include Admin::Detachable
    before_action :set_tabs, only: [:edit, :new]

    def set_tabs
      @tab_names = ["recipe","ingredients","directions","categories"]
      @tab_content = {}
      @tab_content["recipe"] = ["name", "slug", "image", "servings", "cooking_time", "prep_time", "description"]
      @tab_content["ingredients"] = ["recipe_ingredients"]
      @tab_content["directions"] = ["directions"]
      @tab_content["categories"] = ["categories"]
    end

    def default_sorting_attribute
      :updated_at
    end

    def default_sorting_direction
      :desc
    end

  end
end
