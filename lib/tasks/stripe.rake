# frozen_string_literal: true

namespace :stripe do
  desc "Sync plans to Stripe: create Products and Prices. Use mode=test (default) or mode=live. Example: rake stripe:sync_plans mode=live"
  task sync_plans: :environment do
    live_mode = ENV["mode"].to_s.downcase == "live"
    api_key = live_mode ? ENV["STRIPE_SECRET_KEY_LIVE"] : ENV["STRIPE_SECRET_KEY"]
    mode_label = live_mode ? "live" : "test"

    unless api_key.present?
      puts "ERROR: STRIPE_SECRET_KEY#{live_mode ? '_LIVE' : ''} is not set. Cannot sync plans for #{mode_label} mode."
      exit 1
    end

    Stripe.api_key = api_key

    monthly_col = live_mode ? :stripe_price_id_monthly_live : :stripe_price_id_monthly
    yearly_col = live_mode ? :stripe_price_id_yearly_live : :stripe_price_id_yearly

    puts "Syncing plans in #{mode_label} mode..."

    Plan.active.where.not(slug: %w[free enterprise]).find_each do |plan|
      puts "Syncing plan: #{plan.name} (#{plan.slug})"

      product = Stripe::Product.list(limit: 100).data.find { |p| p.metadata["plan_slug"] == plan.slug }
      product ||= Stripe::Product.create(
        name: plan.name,
        description: "Feedback Page - #{plan.name} plan",
        metadata: { plan_slug: plan.slug }
      )

      updates = {}

      if plan.monthly_price_cents.present? && plan.monthly_price_cents.positive? && plan.read_attribute(monthly_col).blank?
        price = Stripe::Price.create(
          product: product.id,
          unit_amount: plan.monthly_price_cents,
          currency: "usd",
          recurring: { interval: "month" },
          metadata: { plan_slug: plan.slug, interval: "month" }
        )
        updates[monthly_col] = price.id
        puts "  Created monthly price: #{price.id}"
      end

      if plan.yearly_price_cents.present? && plan.yearly_price_cents.positive? && plan.read_attribute(yearly_col).blank?
        price = Stripe::Price.create(
          product: product.id,
          unit_amount: plan.yearly_price_cents,
          currency: "usd",
          recurring: { interval: "year" },
          metadata: { plan_slug: plan.slug, interval: "year" }
        )
        updates[yearly_col] = price.id
        puts "  Created yearly price: #{price.id}"
      end

      if updates.any?
        plan.update!(updates)
        puts "  Updated plan in DB"
      else
        puts "  No new prices to create"
      end
    end

    puts "Done."
  end
end
