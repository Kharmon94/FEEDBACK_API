# frozen_string_literal: true

module Api
  module V1
    class PlansController < BaseController
      skip_before_action :authenticate_user!

      def index
        plans = Plan.active.ordered
        render json: { plans: plans.map { |p| plan_json(p) } }, status: :ok
      end

      private

      def plan_json(p)
        {
          id: p.id.to_s,
          slug: p.slug,
          name: p.name,
          monthly_price_cents: p.monthly_price_cents,
          yearly_price_cents: p.yearly_price_cents,
          location_limit: p.location_limit,
          features: p.features,
          cta: p.cta,
          highlighted: p.highlighted,
          display_order: p.display_order
        }
      end
    end
  end
end

