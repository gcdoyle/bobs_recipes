# Admin-only page for running recipe files in db/recipes/ through RecipeImport.
class RecipeImportsController < ApplicationController
  DIRECTORY = Rails.root.join("db/recipes")

  before_action :authenticate_user!
  before_action :require_admin

  def index
    @files = recipe_files
  end

  def create
    file = recipe_files.find { |f| f.basename.to_s == params[:file] }
    return redirect_to(recipe_imports_path, alert: "Unknown file.") unless file

    output = StringIO.new
    @dry_run = params[:dry_run].present?
    @result = RecipeImport.call(path: file, dry_run: @dry_run, out: output)
    @file = file.basename.to_s
    @files = recipe_files
    render :index
  rescue ActiveRecord::RecordInvalid, ArgumentError, Psych::Exception, KeyError => e
    redirect_to recipe_imports_path, alert: "#{file&.basename}: #{e.message}"
  end

  private

  def recipe_files
    DIRECTORY.glob("*.yml").sort
  end

  def require_admin
    redirect_to root_path unless current_user.admin?
  end
end
