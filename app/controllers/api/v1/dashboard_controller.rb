# frozen_string_literal: true

module Api
  module V1
    class DashboardController < BaseController
      def show
        authorize! :read, :dashboard
        locations = current_user.locations
        feedback_count = FeedbackSubmission.joins(:location).where(locations: { user_id: current_user.id }).count
        suggestions_count = Suggestion.joins(:location).where(locations: { user_id: current_user.id }).count
        avg_rating = FeedbackSubmission.joins(:location).where(locations: { user_id: current_user.id }).average(:rating)
        render json: {
          total_feedback: feedback_count,
          total_suggestions: suggestions_count,
          average_rating: avg_rating&.round(1),
          locations_count: locations.count
        }, status: :ok
      end
    end
  end
end
