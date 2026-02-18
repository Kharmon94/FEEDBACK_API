# frozen_string_literal: true

module Api
  module V1
    module Admin
      class AnalyticsController < BaseController
        def index
          render json: {
            revenue: { total: 0, growth: 0, by_plan: [] },
            users: {
              total: User.count,
              growth: 0,
              new_this_month: User.where("created_at >= ?", 1.month.ago).count,
              churn_rate: 0
            },
            feedback: {
              total: FeedbackSubmission.count,
              growth: 0,
              avg_rating: FeedbackSubmission.average(:rating)&.round(1),
              rating_distribution: (1..5).map { |r| { rating: r, count: FeedbackSubmission.where(rating: r).count } }
            },
            top_locations: top_locations_json,
            top_users: top_users_json
          }, status: :ok
        end

        def export
          require "csv"
          top_loc = top_locations_json
          top_usr = top_users_json
          csv = CSV.generate(headers: true) do |row|
            row << %w[metric value]
            row << ["total_users", User.count]
            row << ["total_feedback", FeedbackSubmission.count]
            row << ["avg_rating", FeedbackSubmission.average(:rating)&.round(1)]
            row << []
            row << %w[top_locations id name owner feedback_count avg_rating]
            top_loc.each { |loc| row << [loc[:id], loc[:name], loc[:owner], loc[:feedback_count], loc[:avg_rating]] }
            row << []
            row << %w[top_users id name plan locations_count]
            top_usr.each { |u| row << [u[:id], u[:name], u[:plan], u[:locations_count]] }
          end
          send_data csv, filename: "analytics-#{Date.current.iso8601}.csv", type: "text/csv"
        end

        private

        def top_locations_relation
          Location
            .left_joins(:feedback_submissions)
            .group(:id)
            .select(
              "locations.id",
              "locations.name",
              "locations.user_id",
              "COUNT(feedback_submissions.id) AS feedback_count",
              "AVG(feedback_submissions.rating) AS avg_rating"
            )
            .order("COUNT(feedback_submissions.id) DESC")
            .limit(10)
        end

        def top_locations_json
          locs = top_locations_relation.to_a
          users = User.where(id: locs.map(&:user_id).uniq).index_by(&:id)
          locs.map do |loc|
            {
              id: loc.id.to_s,
              name: loc.name,
              owner: users[loc.user_id]&.name,
              feedback_count: loc.feedback_count.to_i,
              avg_rating: loc.avg_rating&.round(1)
            }
          end
        end

        def top_users_relation
          User
            .left_joins(:locations)
            .group(:id)
            .select("users.id", "users.name", "users.plan", "COUNT(locations.id) AS locations_count")
            .order("COUNT(locations.id) DESC")
            .limit(10)
        end

        def top_users_json
          top_users_relation.map do |u|
            {
              id: u.id.to_s,
              name: u.name,
              plan: u.plan,
              locations_count: u.locations_count.to_i
            }
          end
        end
      end
    end
  end
end
