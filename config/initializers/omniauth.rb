# frozen_string_literal: true

# OmniAuth is mounted in routes at /api/v1/auth so the router dispatches to it
# (avoids middleware ordering issues in API-only mode). path_prefix is empty
# because the mount strips the path; PATH_INFO is e.g. /google_oauth2.
require Rails.root.join("lib", "oauth_callback_handler")

OmniAuth.config.path_prefix = ""
OmniAuth.config.allowed_request_methods = %i[get post]

client_id = Rails.application.credentials.dig(:google_oauth2, :client_id) || ENV["GOOGLE_CLIENT_ID"]
client_secret = Rails.application.credentials.dig(:google_oauth2, :client_secret) || ENV["GOOGLE_CLIENT_SECRET"]

if client_id.present? && client_secret.present?
  OMNIAUTH_APP = OmniAuth::Builder.new do
    provider :google_oauth2, client_id, client_secret, skip_jwt: true
    run OauthCallbackHandler.new
  end
else
  Rails.logger.warn "OmniAuth Google: GOOGLE_CLIENT_ID or GOOGLE_CLIENT_SECRET missing. Google sign-in disabled."
  # Mount a no-op Rack app so the route still exists and returns 503.
  OMNIAUTH_APP = ->(env) { [503, { "Content-Type" => "text/plain" }, ["Google sign-in not configured"]] }
end
