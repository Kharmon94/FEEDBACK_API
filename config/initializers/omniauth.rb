# frozen_string_literal: true

OmniAuth.config.path_prefix = "/api/v1/auth"
OmniAuth.config.allowed_request_methods = %i[get post]

client_id = Rails.application.credentials.dig(:google_oauth2, :client_id) || ENV["GOOGLE_CLIENT_ID"]
client_secret = Rails.application.credentials.dig(:google_oauth2, :client_secret) || ENV["GOOGLE_CLIENT_SECRET"]

# Run OmniAuth before the router so GET /api/v1/auth/google_oauth2 is handled here (redirect to Google),
# not passed to the router which has no matching route and would 404.
Rails.application.config.middleware.insert_before ActionDispatch::Routing::RouteSet, OmniAuth::Builder do
  if client_id.present? && client_secret.present?
    provider :google_oauth2, client_id, client_secret, skip_jwt: true
  else
    Rails.logger.warn "OmniAuth Google: GOOGLE_CLIENT_ID or GOOGLE_CLIENT_SECRET missing (credentials or ENV). Google sign-in disabled."
  end
end
