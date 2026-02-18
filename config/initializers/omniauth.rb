# frozen_string_literal: true

# OmniAuth is added in config/application.rb right after the session store
# so it has env["rack.session"] and runs before the router.
# Google client_id/secret come from credentials or ENV (GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET).
