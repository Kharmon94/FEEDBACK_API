# frozen_string_literal: true

module Api
  module V1
    module Admin
      class SettingsController < BaseController
        def show
          s = AdminSetting.instance
          render json: settings_json(s), status: :ok
        end

        def update
          s = AdminSetting.instance
          s.update!(settings_params)
          render json: { success: true, message: "Settings updated successfully", settings: settings_json(s) }, status: :ok
        end

        private

        def settings_params
          params.permit(
            :site_name,
            :support_email,
            :max_locations_per_user,
            :enable_user_registration,
            :enable_email_verification,
            :enable_social_login
          )
        end

        def settings_json(record)
          {
            site_name: record.site_name,
            support_email: record.support_email,
            max_locations_per_user: record.max_locations_per_user,
            enable_user_registration: record.enable_user_registration,
            enable_email_verification: record.enable_email_verification,
            enable_social_login: record.enable_social_login
          }
        end
      end
    end
  end
end
