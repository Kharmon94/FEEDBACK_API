# frozen_string_literal: true

# CORS allowed origins. FRONTEND_ORIGIN can be comma-separated for multiple (e.g. www + non-www).
origins = ["http://localhost:3000", "http://localhost:5173", "http://127.0.0.1:3000", "http://127.0.0.1:5173"]
if ENV["FRONTEND_ORIGIN"].present?
  ENV["FRONTEND_ORIGIN"].split(",").each do |raw|
    base = raw.strip
    next if base.blank?
    origins << base
    # Add both www and non-www variants
    origins << base.sub("://www.", "://") if base.include?("www.")
    origins << base.sub("://", "://www.") unless base.include?("www.")
  end
  origins.uniq!
end

# Allow Railway preview/staging frontends (e.g. feedback-web-production-xxx.up.railway.app)
origins << %r{\Ahttps://[a-z0-9-]+\.up\.railway\.app\z}
# Allow feedback-page.com with or without www
origins << %r{\Ahttps://(www\.)?feedback-page\.com\z}

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins origins
    resource "*",
      headers: :any,
      methods: %i[get post put patch delete options head],
      expose: ["Authorization"],
      max_age: 600
  end
end
