require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module FeedbackApi
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    # OmniAuth (OAuth callback) requires session middleware. Add cookies + session for API.
    config.middleware.use ActionDispatch::Cookies
    session_options = { key: "_feedback_api_session" }
    if Rails.env.production?
      session_options[:secure] = true
      # Lax allows cookie on top-level redirect from Google; None can be blocked by Safari/ITP.
      session_options[:same_site] = :lax
    end
    config.middleware.use ActionDispatch::Session::CookieStore, **session_options

    # OmniAuth for Google OAuth (after session so state validation works)
    if ENV["GOOGLE_CLIENT_ID"].present? && ENV["GOOGLE_CLIENT_SECRET"].present?
      config.middleware.use OmniAuth::Builder do
        provider :google_oauth2,
          ENV["GOOGLE_CLIENT_ID"],
          ENV["GOOGLE_CLIENT_SECRET"],
          scope: "email,profile"
      end
    end
    OmniAuth.config.allowed_request_methods = %i[get]
  end
end
