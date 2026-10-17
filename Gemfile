source "https://rubygems.org"

ruby "~> 3.4.0"

gem "rails", "~> 8.1.0"
gem "propshaft"
gem "dartsass-rails", "~> 0.5"   # compiles app/assets/stylesheets/application.scss
gem "importmap-rails", "~> 2.2"  # public-site JavaScript (Bootstrap) without a bundler
gem "sqlite3", ">= 2.1"
gem "puma", ">= 6.0"
gem "jbuilder"
gem "image_processing", "~> 1.2"
gem "mini_magick"
gem "bootsnap", require: false

# json 3.x removed the quirks_mode option that some gems still pass
# (ArgumentError on admin requests). Lift once they're updated.
gem "json", "~> 2.10"

# Admin (bundles its own jQuery, selectize, Trix, Turbo and Stimulus)
gem "administrate", "~> 1.0"

gem "devise", "~> 5.0"
gem "friendly_id", "~> 5.5"

group :development, :test do
  gem "debug", platforms: %i[mri windows]
  gem "pry"
end

group :development do
  gem "web-console"
end

group :test do
  # Keep Minitest 5 until Rails' test runner is confirmed on Minitest 6.
  gem "minitest", "~> 5.25"
  gem "capybara"
  gem "selenium-webdriver"
end

gem "tzinfo-data", platforms: %i[windows jruby]
