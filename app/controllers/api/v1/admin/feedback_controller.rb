# frozen_string_literal: true

module Api
  module V1
    module Admin
      class FeedbackController < BaseController
        def index
          subs = FeedbackSubmission.includes(location: :user).order(created_at: :desc)
          subs = subs.where(location_id: params[:location_id]) if params[:location_id].present?
          subs = subs.joins(:location).where(locations: { user_id: params[:user_id] }) if params[:user_id].present?
          subs = subs.where(rating: params[:rating]) if params[:rating].present?
          page = (params[:page] || 1).to_i
          per = (params[:per_page] || 50).to_i
          total = subs.count
          subs = subs.offset((page - 1) * per).limit(per)
          render json: {
            feedback: subs.map { |f| admin_feedback_json(f) },
            pagination: { current_page: page, total_pages: (total.to_f / per).ceil, total_count: total, per_page: per }
          }, status: :ok
        end

        def show
          sub = FeedbackSubmission.find(params[:id])
          render json: admin_feedback_json(sub), status: :ok
        end

        def export
          require "csv"
          subs = FeedbackSubmission.includes(location: :user).order(created_at: :desc)
          csv = CSV.generate(headers: true) do |row|
            row << %w[id rating comment location_id user_id created_at customer_name customer_email]
            subs.each { |f| row << [f.id, f.rating, f.comment, f.location_id, f.location.user_id, f.created_at.iso8601, f.customer_name, f.customer_email] }
          end
          send_data csv, filename: "feedback-#{Date.current.iso8601}.csv", type: "text/csv"
        end

        private

        def admin_feedback_json(f)
          {
            id: f.id.to_s,
            rating: f.rating,
            comment: f.comment,
            location_id: f.location_id.to_s,
            location_name: f.location.name,
            user_id: f.location.user_id.to_s,
            user_name: f.location.user.name,
            user_email: f.location.user.email,
            created_at: f.created_at.iso8601,
            customer_name: f.customer_name,
            customer_email: f.customer_email
          }
        end
      end
    end
  end
end
