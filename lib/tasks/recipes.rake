# frozen_string_literal: true

namespace :recipes do
  desc "Create recipes (and missing ingredients/categories) from a YAML file. DRY_RUN=1 to check without writing."
  task :import, [:path] => :environment do |_task, args|
    abort "Usage: bin/rails \"recipes:import[db/recipes/file.yml]\"" if args[:path].blank?
    RecipeImport.call(path: args[:path], dry_run: ENV["DRY_RUN"].present?)
  end
end
