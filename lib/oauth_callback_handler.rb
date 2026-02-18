# frozen_string_literal: true

# Rack app used as the downstream app for mounted OmniAuth. After OmniAuth sets
# env["omniauth.auth"], this handler creates/finds the user, issues a JWT, and
# redirects to the frontend. Used when OmniAuth is mounted at /api/v1/auth.
class OauthCallbackHandler
  def call(env)
    auth = env["omniauth.auth"]
    frontend = (ENV["FRONTEND_ORIGIN"] || "").gsub(%r{/$}, "")

    if auth.present?
      user = User.from_omniauth(auth)
      token = JwtService.encode({ user_id: user.id })
      url = frontend.present? ? "#{frontend}/auth/callback?token=#{CGI.escape(token)}" : "/"
      return redirect_to(url)
    end

    # Failure or missing auth (e.g. OmniAuth redirected to /failure)
    url = frontend.present? ? "#{frontend}/auth/callback?error=authentication_failed" : "/"
    redirect_to(url)
  end

  private

  def redirect_to(location)
    [302, { "Location" => location, "Content-Type" => "text/html" }, []]
  end
end
