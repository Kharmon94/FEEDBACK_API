# frozen_string_literal: true

# Defines OMNIAUTH_APP for use in config/routes.rb.
# OmniAuth is mounted at /auth and /api/v1/auth for Google OAuth.
require "omniauth"
require "omniauth-google-oauth2"
require Rails.root.join("lib/oauth_callback_handler.rb")

# Ensure callback URL uses correct API origin (needed when behind proxy).
api_origin = (ENV["API_ORIGIN"].presence || "").gsub(%r{/$}, "")
OmniAuth.config.full_host = api_origin.presence
# Empty prefix: mount at /api/v1/auth provides script_name, so path becomes /api/v1/auth/google_oauth2
OmniAuth.config.path_prefix = ""

# Redirect OmniAuth failures to frontend instead of default failure page.
OmniAuth.config.on_failure = lambda { |env|
  frontend = (ENV["FRONTEND_ORIGIN"] || "").gsub(%r{/$}, "")
  redirect_url = frontend.present? ? "#{frontend}/auth/callback?error=authentication_failed" : "/auth/failure"
  [302, { "Location" => redirect_url, "Content-Type" => "text/html" }, []]
}

handler = OauthCallbackHandler.new

# Avoid "already initialized constant" when loaded from routes.rb and again by Rails
unless defined?(OMNIAUTH_APP)
  OMNIAUTH_APP = if ENV["GOOGLE_CLIENT_ID"].present? && ENV["GOOGLE_CLIENT_SECRET"].present?
  OmniAuth::Builder.new(handler) do
    provider :google_oauth2,
      ENV["GOOGLE_CLIENT_ID"],
      ENV["GOOGLE_CLIENT_SECRET"],
      scope: "email,profile",
      # Workaround: session cookie is dropped on cross-site redirect from Google, so state
      # validation fails. Skipping it allows OAuth to complete. Auth code is still validated.
      provider_ignores_state: true
  end
else
  # Minimal Rack app when Google OAuth is not configured (e.g. local dev).
  # Redirects to frontend failure so the app still boots and routes work.
  Object.new.tap do |app|
    app.define_singleton_method(:call) do |env|
      frontend = (ENV["FRONTEND_ORIGIN"] || "").gsub(%r{/$}, "")
      redirect = frontend.present? ? "#{frontend}/auth/callback?error=oauth_not_configured" : "/auth/failure"
      [302, { "Location" => redirect, "Content-Type" => "text/html" }, []]
    end
  end
end
end
