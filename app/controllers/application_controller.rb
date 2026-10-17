class ApplicationController < ActionController::Base
  def search
    return redirect_to(root_path) if params[:q].blank?

    @recipes = Recipe.search(params[:q])
  end
end
