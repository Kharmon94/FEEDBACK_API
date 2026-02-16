# frozen_string_literal: true

module Api
  module V1
    module Admin
      class AnalyticsController < BaseController
        def index
          render json: {
            revenue: { total: 0, growth: 0, by_plan: [] },
            users: { total: User.count, growth: 0, new_this_month: User.where("created_at >= ?", 1.month.ago).count, churn_rate: 0 },
            feedback: {
              total: FeedbackSubmission.count,
              growth: 0,
              avg_rating: FeedbackSubmission.average(:rating)&.round(1),
              rating_distribution: (1..5).map { |r| { rating: r, count: FeedbackSubmission.where(rating: r).count } }
            },
            top_locations: [],
            top_users: []
          }, status: :ok
        end

        def export
          head :ok
        end
      end
    end
  end
end
