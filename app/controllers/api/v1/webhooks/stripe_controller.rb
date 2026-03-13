# frozen_string_literal: true

module Api
  module V1
    module Webhooks
      class StripeController < ApplicationController
        def create
          payload = request.raw_post
          sig_header = request.env["HTTP_STRIPE_SIGNATURE"]

          test_secret = ENV["STRIPE_WEBHOOK_SECRET"].presence
          live_secret = ENV["STRIPE_WEBHOOK_SECRET_LIVE"].presence
          unless test_secret || live_secret
            Rails.logger.warn "[Stripe] Webhook received but no webhook secrets configured"
            return render json: { error: "Webhook not configured" }, status: :service_unavailable
          end

          event = nil
          [test_secret, live_secret].compact.each do |secret|
            begin
              event = Stripe::Webhook.construct_event(payload, sig_header, secret)
              break
            rescue JSON::ParserError => e
              Rails.logger.error "[Stripe] Webhook JSON parse error: #{e.message}"
              return render json: { error: "Invalid payload" }, status: :bad_request
            rescue Stripe::SignatureVerificationError
              next
            end
          end

          unless event
            Rails.logger.error "[Stripe] Webhook signature verification failed for all secrets"
            return render json: { error: "Invalid signature" }, status: :unauthorized
          end

          handle_event(event)
          render json: { received: true }, status: :ok
        rescue => e
          Rails.logger.error "[Stripe] Webhook error: #{e.class} #{e.message}"
          Rails.logger.error e.backtrace.first(10).join("\n")
          render json: { error: "Webhook processing failed" }, status: :internal_server_error
        end

        private

        def handle_event(event)
          case event.type
          when "customer.subscription.created"
            handle_subscription_created(event.data.object)
          when "customer.subscription.updated"
            handle_subscription_updated(event.data.object)
          when "customer.subscription.deleted"
            handle_subscription_deleted(event.data.object)
          when "invoice.paid"
            handle_invoice_paid(event.data.object)
          when "invoice.payment_failed"
            handle_invoice_payment_failed(event.data.object)
          else
            Rails.logger.info "[Stripe] Unhandled event type: #{event.type}"
          end
        end

        def handle_subscription_created(subscription)
          sync_user_from_subscription(subscription)
        end

        def handle_subscription_updated(subscription)
          sync_user_from_subscription(subscription)
        end

        def handle_subscription_deleted(subscription)
          user = find_user_by_customer(subscription.customer)
          return unless user

          plan_name = subscription.metadata&.plan_slug || user.plan

          User.transaction do
            attrs = {
              plan: "free",
              stripe_subscription_id: nil,
              subscription_status: "canceled"
            }
            attrs[:subscription_ends_at] = Time.at(subscription.ended_at) if subscription.ended_at
            user.update!(attrs)
          end

          BillingMailer.subscription_cancelled(
            user,
            plan_name: plan_name.titleize,
            cancellation_date: Date.current.strftime("%B %d, %Y"),
            access_end_date: user.subscription_ends_at&.strftime("%B %d, %Y") || ""
          ).deliver_later
        end

        def stripe_api_key_for_livemode(livemode)
          livemode ? ENV["STRIPE_SECRET_KEY_LIVE"].presence : ENV["STRIPE_SECRET_KEY"].presence
        end

        def handle_invoice_paid(invoice)
          return unless invoice.subscription.present?

          user = find_user_by_customer(invoice.customer)
          return unless user

          opts = { api_key: stripe_api_key_for_livemode(invoice.livemode) }.compact
          subscription = opts[:api_key] ? (Stripe::Subscription.retrieve(invoice.subscription, opts) rescue nil) : nil
          plan_slug = subscription&.metadata&.plan_slug
          price_id = invoice.lines&.data&.first&.price&.id
          plan_slug ||= Plan.find_by(stripe_price_id_monthly: price_id)&.slug || Plan.find_by(stripe_price_id_yearly: price_id)&.slug ||
                        Plan.find_by(stripe_price_id_monthly_live: price_id)&.slug || Plan.find_by(stripe_price_id_yearly_live: price_id)&.slug
          plan_name = Plan.find_by(slug: plan_slug)&.name || plan_slug&.titleize || "Subscription"
          amount = format_money(invoice.amount_paid)
          billing_reason = invoice.billing_reason

          line = invoice.lines&.data&.first
          period_end = line&.period&.end
          next_billing = period_end ? Time.at(period_end).strftime("%B %d, %Y") : ""
          interval = line&.plan&.interval == "year" ? "year" : "month"

          if billing_reason == "subscription_create"
            BillingMailer.payment_successful_first(
              user,
              plan_name: plan_name,
              price: amount,
              billing_cycle: interval,
              invoice_number: invoice.number.to_s,
              next_billing_date: next_billing,
              invoice_url: invoice.hosted_invoice_url.to_s
            ).deliver_later
          elsif billing_reason == "subscription_cycle"
            BillingMailer.payment_successful_recurring(
              user,
              plan_name: plan_name,
              invoice_number: invoice.number.to_s,
              amount: amount,
              next_billing_date: next_billing,
              invoice_url: invoice.hosted_invoice_url.to_s
            ).deliver_later
          end
        end

        def handle_invoice_payment_failed(invoice)
          user = find_user_by_customer(invoice.customer)
          return unless user

          opts = { api_key: stripe_api_key_for_livemode(invoice.livemode) }.compact
          subscription = invoice.subscription.present? && opts[:api_key] ? (Stripe::Subscription.retrieve(invoice.subscription, opts) rescue nil) : nil
          plan_slug = subscription&.metadata&.plan_slug
          plan_name = Plan.find_by(slug: plan_slug)&.name || plan_slug&.titleize || "Subscription"

          failure_reason = if invoice.last_finalization_error&.message.present?
            invoice.last_finalization_error.message
          elsif invoice.lines&.data&.first&.description.present?
            invoice.lines.data.first.description
          else
            "Payment could not be processed"
          end

          BillingMailer.payment_failed(
            user,
            amount: format_money(invoice.amount_due),
            payment_method: "Card on file",
            failure_reason: failure_reason
          ).deliver_later
        end

        def sync_user_from_subscription(subscription)
          user = find_user_by_customer(subscription.customer)
          return unless user

          plan_slug = subscription.metadata&.plan_slug
          plan_slug ||= resolve_plan_slug_from_subscription(subscription)
          plan_slug ||= "free"

          status = subscription.status
          ends_at = subscription.cancel_at ? Time.at(subscription.cancel_at) : nil

          User.transaction do
            user.update!(
              plan: %w[active trialing].include?(status) ? plan_slug : user.plan,
              stripe_subscription_id: subscription.id,
              subscription_status: status,
              subscription_ends_at: ends_at
            )
          end
        end

        def resolve_plan_slug_from_subscription(subscription)
          price_id = subscription.items&.data&.first&.price&.id
          return nil if price_id.blank?

          plan = Plan.find_by(stripe_price_id_monthly: price_id) || Plan.find_by(stripe_price_id_yearly: price_id) ||
                 Plan.find_by(stripe_price_id_monthly_live: price_id) || Plan.find_by(stripe_price_id_yearly_live: price_id)
          plan&.slug
        end

        def find_user_by_customer(customer_id)
          return nil if customer_id.blank?
          User.find_by(stripe_customer_id: customer_id) || User.find_by(stripe_customer_id_live: customer_id)
        end

        def format_money(amount_cents)
          return "$0" if amount_cents.blank?
          "$%.2f" % (amount_cents / 100.0)
        end
      end
    end
  end
end
