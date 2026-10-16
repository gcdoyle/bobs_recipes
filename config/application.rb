require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Recipes
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    # Keep the pre-7.0 key generator digest so existing sessions and the
    # signed IDs embedded in rich-text attachments keep working.
    config.active_support.key_generator_hash_digest_class = OpenSSL::Digest::SHA1

    # Keep ImageMagick for image variants (Rails 7 defaults to libvips).
    config.active_storage.variant_processor = :mini_magick

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
  end
end
