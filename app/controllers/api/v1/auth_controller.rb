# frozen_string_literal: true

module Api
  module V1
    class AuthController < ApplicationController

      def sign_in
        user = User.find_for_database_authentication(email: params[:email])
        if user&.valid_password?(params[:password])
          if AdminSetting.instance.enable_email_verification && !user.confirmed?
            return render json: { error: "Please confirm your email address before signing in." }, status: :unauthorized
          end
          render_auth(user)
        else
          render json: { error: "Invalid email or password" }, status: :unauthorized
        end
      end

      def sign_up
        user = User.new(user_params)
        user.password = params[:password]
        user.confirmed_at = Time.current unless AdminSetting.instance.enable_email_verification
        if user.save
          if AdminSetting.instance.enable_email_verification
            user.send_confirmation_instructions
            render json: { message: "Please check your email to confirm your account.", requires_confirmation: true }, status: :created
          else
            UserMailer.welcome(user).deliver_later
            render_auth(user)
          end
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
        if auth.blank?
          # Session may have been lost on redirect from Google (e.g. cookie SameSite). Send user to failure.
          return failure
        end
        was_new = User.find_by(provider: auth.provider, uid: auth.uid).nil?
        user = User.from_omniauth(auth)
        UserMailer.welcome(user).deliver_later if was_new
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

      def request_password_reset
        user = User.find_by(email: params[:email]&.to_s&.downcase)
        if user
          user.send_reset_password_instructions
        end
        render json: { message: "If an account exists with that email, you will receive password reset instructions." }, status: :ok
      end

      def confirm_email
        user = User.find_by_confirmation_token(params[:token])
        if user
          user.confirm!
          UserMailer.welcome(user).deliver_later
          frontend_origin = (ENV["FRONTEND_ORIGIN"].presence || "https://www.feedback-page.com").gsub(%r{/$}, "")
          redirect_to "#{frontend_origin}/verify-email?confirmed=1", allow_other_host: true
        else
          frontend_origin = (ENV["FRONTEND_ORIGIN"].presence || "https://www.feedback-page.com").gsub(%r{/$}, "")
          redirect_to "#{frontend_origin}/verify-email?error=invalid_token", allow_other_host: true
        end
      end

      def resend_confirmation
        user = User.find_by(email: params[:email]&.to_s&.downcase)
        if user&.confirmed?
          render json: { message: "Email is already confirmed. You can sign in." }, status: :ok
        elsif user
          user.send_confirmation_instructions
          render json: { message: "If an account exists with that email, you will receive confirmation instructions." }, status: :ok
        else
          render json: { message: "If an account exists with that email, you will receive confirmation instructions." }, status: :ok
        end
      end

      def reset_password
        user = User.with_reset_password_token(params[:token])
        unless user
          return render json: { error: "Invalid or expired reset link. Please request a new one." }, status: :unprocessable_entity
        end
        unless user.reset_password_period_valid?
          return render json: { error: "Reset link has expired. Please request a new one." }, status: :unprocessable_entity
        end
        if params[:password].blank?
          return render json: { error: "Password can't be blank" }, status: :unprocessable_entity
        end
        user.password = params[:password]
        user.reset_password_token = nil
        user.reset_password_sent_at = nil
        if user.save
          render json: { message: "Password has been reset. You can now sign in." }, status: :ok
        else
          render json: { error: user.errors.full_messages.join(". ") }, status: :unprocessable_entity
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
