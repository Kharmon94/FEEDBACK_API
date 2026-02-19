# frozen_string_literal: true

module Api
  module V1
    class OptInsController < BaseController
      skip_before_action :authenticate_user!, only: [:create]

      def index
        authorize! :read, OptIn
        scope = OptIn.joins(:location).where(locations: { user_id: current_user.id }).order(created_at: :desc)
        scope = scope.where(location_id: params[:location_id]) if params[:location_id].present?
        opt_ins = scope.to_a
        render json: { opt_ins: opt_ins.map { |o| opt_in_json(o) } }, status: :ok
      end

      def create
        authorize! :create, OptIn
        location = Location.find_by(id: params[:location_id]) || Location.find_by(slug: params[:location_id])
        return render json: { error: "Location not found" }, status: :not_found unless location

        opt_in = location.opt_ins.build(opt_in_params)
        if opt_in.save
          render json: { opt_in: opt_in_json(opt_in) }, status: :created
        else
          render json: { error: opt_in.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def opt_in_params
        params.permit(:name, :email, :phone, :rating)
      end

      def opt_in_json(o)
        {
          id: o.id,
          location_id: o.location_id,
          name: o.name,
          email: o.email,
          phone: o.phone,
          rating: o.rating,
          created_at: o.created_at.iso8601
        }
      end
    end
  end
end
