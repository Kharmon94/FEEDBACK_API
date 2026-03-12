# frozen_string_literal: true

module Api
  module V1
    module Admin
      class LocationsController < BaseController
        def index
          locs = Location.includes(:user).order(created_at: :desc)
          if params[:user_id].present?
            resolved_user = resolve_user_from_param(params[:user_id])
            locs = resolved_user ? locs.where(user_id: resolved_user.id) : locs.where(user_id: nil)
          end
          locs = locs.joins(:user).where("locations.name LIKE ? OR users.name LIKE ? OR users.email LIKE ?", "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%") if params[:search].present?
          page = (params[:page] || 1).to_i
          per = (params[:per_page] || 50).to_i
          total = locs.count
          locs = locs.offset((page - 1) * per).limit(per)
          render json: {
            locations: locs.map { |l| admin_location_json(l) },
            pagination: { current_page: page, total_pages: (total.to_f / per).ceil, total_count: total, per_page: per }
          }, status: :ok
        end

        def show
          loc = resolve_location_from_param(params[:id])
          return render json: { error: "Location not found" }, status: :not_found unless loc
          render json: admin_location_json(loc), status: :ok
        end

        def create
          user = resolve_user_from_param(create_location_params[:user_id])
          return render json: { error: "User not found" }, status: :not_found unless user
          location = user.locations.build(create_location_params.except(:user_id))
          if location.save
            render json: admin_location_json(location.reload), status: :created
          else
            render json: { error: location.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def export
          require "csv"
          locs = Location.includes(:user).order(created_at: :desc)
          csv = CSV.generate(headers: true) do |row|
            row << %w[id name user_id user_email feedback_count created_at]
            locs.each { |l| row << [l.id, l.name, l.user_id, l.user.email, l.feedback_submissions.count, l.created_at.iso8601] }
          end
          send_data csv, filename: "locations-#{Date.current.iso8601}.csv", type: "text/csv"
        end

        private

        def admin_location_json(l)
          {
            id: l.id.to_s,
            public_id: LocationIdObfuscator.encode(l.id),
            name: l.name,
            user_id: l.user_id.to_s,
            user_public_id: UserIdObfuscator.encode(l.user_id),
            user_name: l.user.name,
            user_email: l.user.email,
            feedback_count: l.feedback_submissions.count,
            avg_rating: l.feedback_submissions.average(:rating)&.round(1),
            created_at: l.created_at.iso8601
          }
        end

        def create_location_params
          params.permit(:user_id, :name)
        end
      end
    end
  end
end
