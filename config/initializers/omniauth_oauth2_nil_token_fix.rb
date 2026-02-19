# frozen_string_literal: true

# Patch omniauth-oauth2 to handle nil access_token gracefully.
# When the callback is hit without a valid auth code (e.g. user denied, HEAD request, or
# session loss), build_access_token returns nil and the gem raises NoMethodError on
# access_token.expired? See: https://github.com/omniauth/omniauth-oauth2/issues/138
Rails.application.config.after_initialize do
  OmniAuth::Strategies::OAuth2.class_eval do
    def callback_phase
      error = request.params["error_reason"] || request.params["error"]
      if !options.provider_ignores_state && (request.params["state"].to_s.empty? || !secure_compare(request.params["state"], session.delete("omniauth.state")))
        return fail!(:csrf_detected, CallbackError.new(:csrf_detected, "CSRF detected"))
      end
      if error
        return fail!(error, CallbackError.new(request.params["error"], request.params["error_description"] || request.params["error_reason"], request.params["error_uri"]))
      end

      self.access_token = build_access_token
      if access_token.nil?
        return fail!(:invalid_credentials, CallbackError.new(:invalid_credentials, "No access token received (missing or invalid authorization code)"))
      end
      self.access_token = access_token.refresh! if access_token.expired?
      super
    end
  end
end
