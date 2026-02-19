# frozen_string_literal: true

module Api
  module V1
    class GoogleOauthController < ApplicationController
      # OmniAuth processes callback; we only receive successful flows.
      # On failure, OmniAuth's on_failure redirects before we're reached.
      def callback
        auth = request.env["omniauth.auth"]
        frontend = (ENV["FRONTEND_ORIGIN"] || "").gsub(%r{/$}, "")

        unless frontend.present?
          return render plain: "FRONTEND_ORIGIN is not set.", status: :service_unavailable
        end

        if auth.present?
          user = User.from_omniauth(auth)
          token = JwtService.encode({ user_id: user.id })
          redirect_to "#{frontend}/auth/callback?token=#{CGI.escape(token)}", allow_other_host: true
        else
          redirect_to "#{frontend}/auth/callback?error=authentication_failed", allow_other_host: true
        end
      end

      # Only hit when OmniAuth is not in the stack (credentials missing).
      def redirect_if_not_configured
        frontend = (ENV["FRONTEND_ORIGIN"] || "").gsub(%r{/$}, "")
        redirect_url = frontend.present? ? "#{frontend}/auth/callback?error=oauth_not_configured" : "/auth/failure"
        redirect_to redirect_url, allow_other_host: true
      end
    end
  end
end
