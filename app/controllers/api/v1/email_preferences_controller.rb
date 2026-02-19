# frozen_string_literal: true

module Api
  module V1
    class EmailPreferencesController < BaseController
      skip_before_action :authenticate_user!, only: %i[unsubscribe]
      before_action :verify_unsubscribe_token, only: %i[unsubscribe]

      def show
        render json: {
          email_notifications_enabled: current_user.email_notifications_enabled?,
          email_marketing_opt_out: current_user.email_marketing_opted_out?
        }, status: :ok
      end

      def update
        current_user.assign_attributes(email_preferences_params)
        if current_user.save
          render json: {
            email_notifications_enabled: current_user.email_notifications_enabled?,
            email_marketing_opt_out: current_user.email_marketing_opted_out?
          }, status: :ok
        else
          render json: { error: current_user.errors.full_messages.first }, status: :unprocessable_entity
        end
      end

      def unsubscribe
        if @unsubscribe_user
          @unsubscribe_user.update!(
            email_notifications_enabled: false,
            email_marketing_opt_out: true
          )
          redirect_to "#{frontend_origin}/email-preferences/unsubscribe?success=1", allow_other_host: true
        else
          redirect_to "#{frontend_origin}/email-preferences/unsubscribe?error=invalid_token", allow_other_host: true
        end
      end

      private

      def email_preferences_params
        params.permit(:email_notifications_enabled, :email_marketing_opt_out)
      end

      def verify_unsubscribe_token
        token = params[:token]
        return unless token.present?

        begin
          data = Rails.application.message_verifier(:email_unsubscribe).verify(token)
          raise "invalid" unless data.is_a?(Hash) && data[:user_id].present?
          raise "expired" if data[:exp].present? && Time.at(data[:exp]) < Time.current

          @unsubscribe_user = User.find_by(id: data[:user_id])
        rescue ActiveSupport::MessageVerifier::InvalidSignature, StandardError
          @unsubscribe_user = nil
        end
      end

      def frontend_origin
        origin = (ENV["FRONTEND_ORIGIN"].presence || "https://www.feedback-page.com").to_s.gsub(%r{/$}, "")
        origin.include?("://") ? origin : "https://#{origin}"
      end
    end
  end
end
