# frozen_string_literal: true

# Defines OMNIAUTH_APP for use in config/routes.rb.
# OmniAuth is mounted at /auth and /api/v1/auth for Google OAuth.
require "omniauth"
require "omniauth-google-oauth2"

handler = OauthCallbackHandler.new

OMNIAUTH_APP = if ENV["GOOGLE_CLIENT_ID"].present? && ENV["GOOGLE_CLIENT_SECRET"].present?
  OmniAuth::Builder.new(handler) do
    provider :google_oauth2,
      ENV["GOOGLE_CLIENT_ID"],
      ENV["GOOGLE_CLIENT_SECRET"],
      scope: "email,profile"
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
