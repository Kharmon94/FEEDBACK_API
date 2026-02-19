# frozen_string_literal: true

origins = ["http://localhost:3000", "http://localhost:5173", "http://127.0.0.1:3000", "http://127.0.0.1:5173"]
if ENV["FRONTEND_ORIGIN"].present?
  base = ENV["FRONTEND_ORIGIN"].strip
  origins << base
  # Allow both www and non-www variants (e.g. www.feedback-page.com and feedback-page.com)
  origins << base.sub("://www.", "://") if base.include?("www.")
  origins << base.sub("://", "://www.") unless base.include?("www.")
  origins.uniq!
end

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins origins
    resource "*",
      headers: :any,
      methods: %i[get post put patch delete options head],
      expose: ["Authorization"]
  end
end
