# frozen_string_literal: true

require "csv"

module Api
  module V1
    class ExportController < BaseController
      def feedback
        authorize! :read, FeedbackSubmission
        submissions = FeedbackSubmission.joins(:location).where(locations: { user_id: current_user.id }).order(created_at: :desc)
        csv = CSV.generate(headers: true) do |row|
          row << %w[id location_id rating comment customer_name customer_email created_at]
          submissions.each { |f| row << [f.id, f.location_id, f.rating, f.comment, f.customer_name, f.customer_email, f.created_at.iso8601] }
        end
        send_data csv, filename: "feedback-#{Date.current.iso8601}.csv", type: "text/csv"
      end

      def suggestions
        authorize! :read, Suggestion
        suggestions = Suggestion.joins(:location).where(locations: { user_id: current_user.id }).order(created_at: :desc)
        csv = CSV.generate(headers: true) do |row|
          row << %w[id content submitter_email location_id created_at]
          suggestions.each { |s| row << [s.id, s.content, s.submitter_email, s.location_id, s.created_at.iso8601] }
        end
        send_data csv, filename: "suggestions-#{Date.current.iso8601}.csv", type: "text/csv"
      end
    end
  end
end
