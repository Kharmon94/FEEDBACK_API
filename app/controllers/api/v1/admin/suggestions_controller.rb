# frozen_string_literal: true

module Api
  module V1
    module Admin
      class SuggestionsController < BaseController
        def index
          sugg = Suggestion.includes(location: :user).order(created_at: :desc)
          sugg = sugg.where(location_id: params[:location_id]) if params[:location_id].present?
          sugg = sugg.joins(:location).where(locations: { user_id: params[:user_id] }) if params[:user_id].present?
          page = (params[:page] || 1).to_i
          per = (params[:per_page] || 50).to_i
          total = sugg.count
          sugg = sugg.offset((page - 1) * per).limit(per)
          render json: {
            suggestions: sugg.map { |s| admin_suggestion_json(s) },
            pagination: { current_page: page, total_pages: (total.to_f / per).ceil, total_count: total, per_page: per }
          }, status: :ok
        end

        def show
          s = Suggestion.find(params[:id])
          render json: admin_suggestion_json(s), status: :ok
        end

        def export
          require "csv"
          sugg = Suggestion.includes(location: :user).order(created_at: :desc)
          csv = CSV.generate(headers: true) do |row|
            row << %w[id content submitter_email location_id location_name user_id created_at]
            sugg.each do |s|
              row << [
                s.id,
                s.content,
                s.submitter_email,
                s.location_id,
                s.location&.name,
                s.location&.user_id,
                s.created_at.iso8601
              ]
            end
          end
          send_data csv, filename: "suggestions-#{Date.current.iso8601}.csv", type: "text/csv"
        end

        private

        def admin_suggestion_json(s)
          {
            id: s.id.to_s,
            content: s.content,
            submitter_email: s.submitter_email,
            location_id: s.location_id&.to_s,
            location_name: s.location&.name,
            user_id: s.location&.user_id&.to_s,
            user_name: s.location&.user&.name,
            user_email: s.location&.user&.email,
            created_at: s.created_at.iso8601
          }
        end
      end
    end
  end
end
