# frozen_string_literal: true

module Api
  module V1
    class ContactController < BaseController
      skip_before_action :authenticate_user!

      def create
        name = params[:name].to_s.strip.presence || (current_user&.name)
        email = params[:email].to_s.strip.presence || current_user&.email
        phone = params[:phone].to_s.strip.presence
        subject = params[:subject].to_s.strip.presence
        message = params[:message].to_s.strip.presence

        if email.blank?
          return render json: { error: "Email is required" }, status: :unprocessable_entity
        end
        if subject.blank?
          return render json: { error: "Subject is required" }, status: :unprocessable_entity
        end
        if message.blank?
          return render json: { error: "Message is required" }, status: :unprocessable_entity
        end

        source = current_user ? "dashboard_support" : "contact_us"
        ContactMailer.contact_submission(
          name: name,
          email: email,
          phone: phone,
          subject: subject,
          message: message,
          source: source
        ).deliver_later

        render json: { success: true }, status: :ok
      rescue => e
        Rails.logger.error "[Contact] Failed to send: #{e.message}"
        render json: { error: "Failed to send message. Please try again." }, status: :internal_server_error
      end
    end
  end
end
