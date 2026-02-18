# frozen_string_literal: true

module Api
  module V1
    module Admin
      class DashboardController < BaseController
        def index
          render json: {
            total_users: User.count,
            active_users: User.where(suspended: false).count,
            total_locations: Location.count,
            total_feedback: FeedbackSubmission.count,
            avg_rating: FeedbackSubmission.average(:rating)&.round(1),
            recent_activity: recent_activity_items
          }, status: :ok
        end

        private

        def recent_activity_items
          users = User.order(created_at: :desc).limit(4).map do |u|
            { type: "user", id: u.id.to_s, message: "New user: #{u.name.presence || u.email}", created_at: u.created_at.iso8601, user_name: u.name, user_email: u.email }
          end
          locations = Location.includes(:user).order(created_at: :desc).limit(4).map do |loc|
            { type: "location", id: loc.id.to_s, message: "New location: #{loc.name}", created_at: loc.created_at.iso8601, location_name: loc.name, user_name: loc.user.name }
          end
          feedback = FeedbackSubmission.includes(location: :user).order(created_at: :desc).limit(4).map do |f|
            msg = "New feedback (#{f.rating} stars) for #{f.location.name}"
            { type: "feedback", id: f.id.to_s, message: msg, created_at: f.created_at.iso8601, location_name: f.location.name, user_name: f.location.user.name }
          end
          (users + locations + feedback).sort_by { |h| h[:created_at] }.reverse.first(10)
        end
      end
    end
  end
end
