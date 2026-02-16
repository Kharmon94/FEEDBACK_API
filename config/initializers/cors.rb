# frozen_string_literal: true

origins = ["http://localhost:3000", "http://localhost:5173", "http://127.0.0.1:3000", "http://127.0.0.1:5173"]
origins << ENV["FRONTEND_ORIGIN"] if ENV["FRONTEND_ORIGIN"].present?

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins origins
    resource "*",
      headers: :any,
      methods: %i[get post put patch delete options head],
      expose: ["Authorization"]
  end
end
