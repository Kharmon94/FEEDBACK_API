# frozen_string_literal: true

module Api
  module V1
    class PortalController < BaseController
      include Concerns::StripeMode

      def create_session
        return render json: { error: "Stripe is not configured" }, status: :service_unavailable unless stripe_configured?

        customer_id = stripe_customer_id_for_user(current_user)
        if customer_id.blank?
          return render json: { error: "No billing account found. Subscribe to a plan first." }, status: :unprocessable_entity
        end

        session = Stripe::BillingPortal::Session.create(
          { customer: customer_id, return_url: "#{frontend_origin}/dashboard?tab=settings" },
          { api_key: stripe_api_key }
        )
        render json: { url: session.url }, status: :ok
      rescue Stripe::StripeError => e
        Rails.logger.error "[Stripe] Portal error: #{e.message}"
        render json: { error: "Could not open billing portal. Please try again." }, status: :unprocessable_entity
      end
    end
  end
end
