# frozen_string_literal: true

OmniAuth.config.path_prefix = "/api/v1/auth"
OmniAuth.config.allowed_request_methods = %i[get post]

client_id = Rails.application.credentials.dig(:google_oauth2, :client_id) || ENV["GOOGLE_CLIENT_ID"]
client_secret = Rails.application.credentials.dig(:google_oauth2, :client_secret) || ENV["GOOGLE_CLIENT_SECRET"]

# OmniAuth must run after session (it needs env["rack.session"]) but before the router.
# insert_after Session::CookieStore so session is loaded; we're still before the router.
Rails.application.config.middleware.insert_after ActionDispatch::Session::CookieStore, OmniAuth::Builder do
  if client_id.present? && client_secret.present?
    provider :google_oauth2, client_id, client_secret, skip_jwt: true
  else
    Rails.logger.warn "OmniAuth Google: GOOGLE_CLIENT_ID or GOOGLE_CLIENT_SECRET missing (credentials or ENV). Google sign-in disabled."
  end
end
