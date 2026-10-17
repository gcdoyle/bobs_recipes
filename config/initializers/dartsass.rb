# Dart Sass builds app/assets/stylesheets/application.scss into
# app/assets/builds/application.css. In development, bin/dev runs
# `bin/rails dartsass:watch` (see Procfile.dev); assets:precompile and the test
# runner build it automatically.
#
# Asset paths (including vendor/assets/stylesheets) are Sass load paths, which is
# how `@import "bootstrap/bootstrap"` finds Bootstrap's source.
Rails.application.config.dartsass.builds = { "application.scss" => "application.css" }

# Bootstrap 5.3 still uses @import internally, so quiet the deprecation
# warnings it would otherwise print on every build.
Rails.application.config.dartsass.build_options = [
  "--style=compressed", "--no-source-map", "--quiet-deps", "--silence-deprecation=import"
]
