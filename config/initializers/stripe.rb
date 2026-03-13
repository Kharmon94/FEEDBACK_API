# frozen_string_literal: true

Rails.application.config.to_prepare do
  Stripe.api_key = ENV["STRIPE_SECRET_KEY"] if ENV["STRIPE_SECRET_KEY"].present?
end
