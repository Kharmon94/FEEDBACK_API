# frozen_string_literal: true

module Api
  module V1
    class BaseController < ApplicationController
      before_action :authenticate_user!

      private

      def resolve_location_from_param(param)
        return nil if param.blank?

        decoded_id = LocationIdObfuscator.decode(param)
        if decoded_id
          Location.find_by(id: decoded_id)
        else
          Location.find_by(id: param) || Location.find_by(slug: param)
        end
      end

      def resolve_user_from_param(param)
        return nil if param.blank?

        decoded_id = UserIdObfuscator.decode(param)
        if decoded_id
          User.find_by(id: decoded_id)
        else
          User.find_by(id: param)
        end
      end

      def authenticate_user!
        token = request.headers["Authorization"]&.split(" ")&.last
        payload = token ? JwtService.decode(token) : nil
        if payload && payload[:user_id]
          @current_user = User.find_by(id: payload[:user_id])
          @current_user = nil if @current_user&.suspended?
        end
        render json: { error: "Unauthorized" }, status: :unauthorized unless @current_user
      end

      def current_user
        @current_user
      end
    end
  end
end
