# frozen_string_literal: true

namespace :sync do
  desc "Create ingredients from an Open Food Facts export (default ingredients.json). DRY_RUN=1 to preview."
  task :ingredients, [:path] => :environment do |_task, args|
    SyncService::Ingredients.call(path: args[:path], dry_run: ENV["DRY_RUN"].present?)
  end
end
