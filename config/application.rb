# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module OktaExamples
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.x.okta.issuer = ENV['OKTA_ISSUER']
    config.x.okta.client_id = ENV['OKTA_CLIENT_ID']
    config.x.okta.client_secret = ENV['OKTA_CLIENT_SECRET']
    config.x.okta.redirect_uri = ENV['OKTA_REDIRECT_URI']
  end
end
