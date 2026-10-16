source "https://rubygems.org"

ruby "~> 3.4.0"

gem "rails", "~> 7.2.0"
gem "sprockets-rails"
gem "pg", "~> 1.5"
gem "puma", ">= 6.0"
gem "sass-rails", ">= 6"
gem "jbuilder"
gem "image_processing", "~> 1.2"
gem "mini_magick"
gem "bootsnap", require: false

# json 3.x removed the quirks_mode option that some gems still pass
# (ArgumentError on admin requests). Lift once they're updated.
gem "json", "~> 2.10"

# Admin
gem "administrate", "~> 0.20.1"
gem "administrate-field-nested_has_many", "~> 2.1"
gem "administrate-field-trix"
gem "trix-rails", require: "trix"

gem "devise", "~> 4.9"
gem "friendly_id", "~> 5.5"
gem "bootstrap", "~> 4.6.2"
gem "popper_js", "~> 1.16.0"

group :production do
  # Bootstrap 4 runs autoprefixer during assets:precompile, which needs a
  # JavaScript runtime. macOS has one built in; Linux servers don't.
  gem "mini_racer"
end

group :development, :test do
  gem "debug", platforms: %i[mri windows]
  gem "pry"
end

group :development do
  gem "web-console"
end

group :test do
  # Rails 7.2's test runner doesn't support Minitest 6.
  gem "minitest", "~> 5.25"
  gem "capybara"
  gem "selenium-webdriver"
end

gem "tzinfo-data", platforms: %i[windows jruby]
