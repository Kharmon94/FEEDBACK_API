# frozen_string_literal: true

module Api
  module V1
    class CheckoutController < BaseController
      include Concerns::StripeMode

      def create_session
        plan_slug = params[:plan_slug].to_s.presence
        billing_period = params[:billing_period].to_s.presence
        billing_period = "monthly" unless %w[monthly yearly].include?(billing_period)

        return render json: { error: "plan_slug is required" }, status: :unprocessable_entity if plan_slug.blank?

        plan = Plan.find_by(slug: plan_slug, active: true)
        return render json: { error: "Plan not found" }, status: :not_found unless plan

        price_id = billing_period == "yearly" ? stripe_price_id_yearly(plan) : stripe_price_id_monthly(plan)
        return render json: { error: "Plan does not have a Stripe price configured" }, status: :unprocessable_entity if price_id.blank?

        unless stripe_configured?
          return render json: { error: "Stripe is not configured" }, status: :service_unavailable
        end

        api_key = stripe_api_key
        customer_id = stripe_customer_id_for_user(current_user)
        if customer_id.blank?
          customer = Stripe::Customer.create(
            { email: current_user.email, name: current_user.name, metadata: { user_id: current_user.id.to_s } },
            { api_key: api_key }
          )
          customer_id = customer.id
          set_stripe_customer_id_for_user(current_user, customer_id)
        end

        session_params = {
          customer: customer_id,
          mode: "subscription",
          line_items: [{ price: price_id, quantity: 1 }],
          success_url: "#{frontend_origin}/dashboard?tab=billing&checkout=success",
          cancel_url: "#{frontend_origin}/pricing?checkout=cancelled",
          metadata: { user_id: current_user.id.to_s, plan_slug: plan_slug, billing_period: billing_period },
          subscription_data: {
            metadata: { user_id: current_user.id.to_s, plan_slug: plan_slug },
            trial_period_days: plan.slug == "free" ? 0 : 30
          }
        }

        session = Stripe::Checkout::Session.create(session_params, { api_key: api_key })
        render json: { url: session.url }, status: :ok
      rescue Stripe::StripeError => e
        Rails.logger.error "[Stripe] Checkout error: #{e.message}"
        render json: { error: "Payment processing error. Please try again." }, status: :unprocessable_entity
      end
    end
  end
end
