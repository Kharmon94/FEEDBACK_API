# frozen_string_literal: true

module Api
  module V1
    module Admin
      class SettingsController < BaseController
        def show
          render json: {
            site_name: "Feedback Page",
            support_email: "support@feedbackpage.com",
            max_locations_per_user: 100,
            enable_user_registration: true,
            enable_email_verification: false,
            enable_social_login: true
          }, status: :ok
        end

        def update
          render json: { success: true, message: "Settings updated successfully", settings: {} }, status: :ok
        end
      end
    end
  end
end
