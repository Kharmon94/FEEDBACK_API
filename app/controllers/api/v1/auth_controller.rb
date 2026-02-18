# frozen_string_literal: true

module Api
  module V1
    class AuthController < ApplicationController

      def sign_in
        user = User.find_for_database_authentication(email: params[:email])
        if user&.valid_password?(params[:password])
          render_auth(user)
        else
          render json: { error: "Invalid email or password" }, status: :unauthorized
        end
      end

      def sign_up
        user = User.new(user_params)
        user.password = params[:password]
        if user.save
          render_auth(user)
        else
          msg = user.errors.full_messages.first || "Registration failed"
          msg = "Email has already been taken. Please sign in instead." if msg.downcase.include?("already been taken")
          render json: { error: msg, details: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def me
        authenticate_user!
        render json: { user: user_json(current_user) }, status: :ok
      end

      def omniauth_callback
        auth = request.env["omniauth.auth"]
        user = User.from_omniauth(auth)
        token = JwtService.encode({ user_id: user.id })
        frontend_origin = ENV["FRONTEND_ORIGIN"].to_s.gsub(%r{/$}, "")
        if frontend_origin.present?
          redirect_to "#{frontend_origin}/auth/callback?token=#{CGI.escape(token)}", allow_other_host: true
        else
          render_auth(user)
        end
      end

      def failure
        frontend_origin = ENV["FRONTEND_ORIGIN"].to_s.gsub(%r{/$}, "")
        if frontend_origin.present?
          redirect_to "#{frontend_origin}/auth/callback?error=authentication_failed", allow_other_host: true
        else
          render json: { error: "Authentication failed" }, status: :unauthorized
        end
      end

      private

      def authenticate_user!
        token = request.headers["Authorization"]&.split(" ")&.last
        payload = token ? JwtService.decode(token) : nil
        @current_user = payload && payload[:user_id] ? User.find_by(id: payload[:user_id]) : nil
        render json: { error: "Unauthorized" }, status: :unauthorized unless @current_user
      end

      def current_user
        @current_user
      end

      def render_auth(user)
        token = JwtService.encode({ user_id: user.id })
        render json: { token: token, user: user_json(user) }, status: :ok
      end

      def user_json(u)
        {
          id: u.id,
          email: u.email,
          name: u.name,
          business_name: u.business_name,
          plan: u.plan,
          admin: u.admin
        }
      end

      def user_params
        params.permit(:email, :name, :business_name).to_h
      end
    end
  end
end
