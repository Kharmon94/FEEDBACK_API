# frozen_string_literal: true

# OmniAuth must run after session (added in application.rb). We add it here so
# ENV/credentials are available when the provider is registered.
OmniAuth.config.path_prefix = "/api/v1/auth"
OmniAuth.config.allowed_request_methods = %i[get post]

client_id = Rails.application.credentials.dig(:google_oauth2, :client_id) || ENV["GOOGLE_CLIENT_ID"]
client_secret = Rails.application.credentials.dig(:google_oauth2, :client_secret) || ENV["GOOGLE_CLIENT_SECRET"]

Rails.application.config.middleware.use OmniAuth::Builder do
  if client_id.present? && client_secret.present?
    provider :google_oauth2, client_id, client_secret, skip_jwt: true
  else
    Rails.logger.warn "OmniAuth Google: GOOGLE_CLIENT_ID or GOOGLE_CLIENT_SECRET missing. Google sign-in disabled."
  end
end
