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
            recent_activity: []
          }, status: :ok
        end
      end
    end
  end
end
