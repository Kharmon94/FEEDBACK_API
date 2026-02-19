# frozen_string_literal: true

# OmniAuth config. Provider is added in config/application.rb after session.
# full_host for correct redirect_uri when behind proxy (e.g. Railway).
api_origin = (ENV["API_ORIGIN"].presence || "").gsub(%r{/$}, "")
OmniAuth.config.full_host = api_origin.presence

# Redirect failures to frontend
OmniAuth.config.on_failure = lambda { |env|
  frontend = (ENV["FRONTEND_ORIGIN"] || "").gsub(%r{/$}, "")
  redirect_url = frontend.present? ? "#{frontend}/auth/callback?error=authentication_failed" : "/auth/failure"
  [302, { "Location" => redirect_url, "Content-Type" => "text/html" }, []]
}
