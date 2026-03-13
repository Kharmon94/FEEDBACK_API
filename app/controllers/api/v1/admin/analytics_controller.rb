# frozen_string_literal: true

module Api
  module V1
    module Admin
      class AnalyticsController < BaseController
        def index
          users_rel = base_users_relation
          feedback_rel = base_feedback_relation

          render json: {
            revenue: { total: 0, growth: 0, by_plan: [] },
            users: {
              total: users_rel.count,
              growth: 0,
              new_this_month: users_rel.where("created_at >= ?", 1.month.ago).count,
              churn_rate: 0
            },
            feedback: {
              total: feedback_rel.count,
              growth: 0,
              avg_rating: feedback_rel.average(:rating)&.round(1),
              rating_distribution: (1..5).map { |r| { rating: r, count: feedback_rel.where(rating: r).count } }
            },
            top_locations: top_locations_json,
            top_users: top_users_json
          }, status: :ok
        end

        def export
          require "csv"
          users_rel = base_users_relation
          feedback_rel = base_feedback_relation
          top_loc = top_locations_json
          top_usr = top_users_json
          csv = CSV.generate(headers: true) do |row|
            row << %w[metric value]
            row << ["total_users", users_rel.count]
            row << ["total_feedback", feedback_rel.count]
            row << ["avg_rating", feedback_rel.average(:rating)&.round(1)]
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

        def since_date
          return nil unless params[:since].present?

          n = params[:since].to_s.downcase
          case n
          when "today" then Time.current.beginning_of_day
          when "7d" then 7.days.ago
          when "30d" then 30.days.ago
          when "90d" then 90.days.ago
          when "6m" then 6.months.ago
          when "1y" then 1.year.ago
          else nil
          end
        end

        def scoped_location_ids
          if params[:location_id].present?
            loc = resolve_location_from_param(params[:location_id])
            loc ? [loc.id] : []
          elsif params[:user_id].present?
            usr = resolve_user_from_param(params[:user_id])
            usr ? usr.locations.pluck(:id) : []
          else
            nil
          end
        end

        def scoped_user_ids
          if params[:user_id].present?
            usr = resolve_user_from_param(params[:user_id])
            usr ? [usr.id] : []
          elsif params[:location_id].present?
            loc = resolve_location_from_param(params[:location_id])
            loc ? [loc.user_id] : []
          else
            nil
          end
        end

        def base_users_relation
          rel = User.all
          user_ids = scoped_user_ids
          rel = rel.where(id: user_ids) if user_ids && !user_ids.empty?
          sd = since_date
          rel = rel.where("created_at >= ?", sd) if sd
          rel
        end

        def base_feedback_relation
          rel = FeedbackSubmission.all
          loc_ids = scoped_location_ids
          rel = rel.where(location_id: loc_ids) if loc_ids && !loc_ids.empty?
          if loc_ids.nil? && scoped_user_ids.present?
            rel = rel.joins(:location).where(locations: { user_id: scoped_user_ids })
          end
          sd = since_date
          rel = rel.where("created_at >= ?", sd) if sd
          rel
        end

        def top_locations_relation
          rel = Location.left_joins(:feedback_submissions)
          rel = rel.where("feedback_submissions.created_at >= ?", since_date) if since_date
          loc_ids = scoped_location_ids
          rel = rel.where(locations: { id: loc_ids }) if loc_ids && !loc_ids.empty?
          if loc_ids.nil? && scoped_user_ids.present?
            rel = rel.where(locations: { user_id: scoped_user_ids })
          end
          rel
            .group("locations.id")
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
          users = User.where(id: locs.map(&:user_id).uniq.compact).index_by(&:id)
          locs.map do |loc|
            {
              id: loc.id.to_s,
              public_id: LocationIdObfuscator.encode(loc.id),
              name: loc.name,
              owner: users[loc.user_id]&.name,
              feedback_count: loc.feedback_count.to_i,
              avg_rating: loc.avg_rating&.round(1)
            }
          end
        end

        def top_users_relation
          rel = User.left_joins(:locations)
          user_ids = scoped_user_ids
          rel = rel.where(users: { id: user_ids }) if user_ids && !user_ids.empty?
          if user_ids.nil? && scoped_location_ids.present?
            rel = rel.where(locations: { id: scoped_location_ids })
          end
          rel
            .group("users.id")
            .select("users.id", "users.name", "users.plan", "COUNT(locations.id) AS locations_count")
            .order("COUNT(locations.id) DESC")
            .limit(10)
        end

        def top_users_json
          top_users_relation.map do |u|
            {
              id: u.id.to_s,
              public_id: UserIdObfuscator.encode(u.id),
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
