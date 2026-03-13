# frozen_string_literal: true

module Concerns
  module StripeMode
    extend ActiveSupport::Concern

    def stripe_live_mode?
      return false unless AdminSetting.table_exists?
      AdminSetting.instance.respond_to?(:stripe_live_mode) && AdminSetting.instance.stripe_live_mode
    end

    def stripe_api_key
      if stripe_live_mode?
        ENV["STRIPE_SECRET_KEY_LIVE"].presence
      else
        ENV["STRIPE_SECRET_KEY"].presence
      end
    end

    def stripe_configured?
      stripe_api_key.present?
    end

    def stripe_price_id_monthly(plan)
      stripe_live_mode? ? plan.stripe_price_id_monthly_live : plan.stripe_price_id_monthly
    end

    def stripe_price_id_yearly(plan)
      stripe_live_mode? ? plan.stripe_price_id_yearly_live : plan.stripe_price_id_yearly
    end

    def stripe_customer_id_for_user(user)
      stripe_live_mode? ? user.stripe_customer_id_live : user.stripe_customer_id
    end

    def set_stripe_customer_id_for_user(user, customer_id)
      if stripe_live_mode?
        user.update_column(:stripe_customer_id_live, customer_id)
      else
        user.update_column(:stripe_customer_id, customer_id)
      end
    end
  end
end
