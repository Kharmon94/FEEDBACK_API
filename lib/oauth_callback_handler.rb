# frozen_string_literal: true

# Rack app used as the downstream app for mounted OmniAuth. After OmniAuth sets
# env["omniauth.auth"], this handler creates/finds the user, issues a JWT, and
# redirects to the frontend. Used when OmniAuth is mounted at /api/v1/auth.
class OauthCallbackHandler
  def call(env)
    auth = env["omniauth.auth"]
    frontend = (ENV["FRONTEND_ORIGIN"] || "").gsub(%r{/$}, "")

    unless frontend.present?
      return [503, { "Content-Type" => "text/plain" }, ["FRONTEND_ORIGIN is not set. Set it in the environment to redirect after sign-in."]]
    end

    if auth.present?
      user = User.from_omniauth(auth)
      token = JwtService.encode({ user_id: user.id })
      return redirect_to("#{frontend}/auth/callback?token=#{CGI.escape(token)}")
    end

    # Failure or missing auth (e.g. session lost on redirect, user denied)
    omniauth_error = env["omniauth.error"]
    error_type = omniauth_error&.respond_to?(:error) ? omniauth_error.error : "authentication_failed"
    error_desc = omniauth_error&.respond_to?(:message) ? omniauth_error.message : nil
    query = "error=#{CGI.escape(error_type)}"
    query += "&error_description=#{CGI.escape(error_desc)}" if error_desc.present?
    redirect_to("#{frontend}/auth/callback?#{query}")
  end

  private

  def redirect_to(location)
    [302, { "Location" => location, "Content-Type" => "text/html" }, []]
  end
end
