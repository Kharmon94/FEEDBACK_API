# frozen_string_literal: true

class AdminSetting < ApplicationRecord
  def self.instance
    first || create!(
      site_name: "Feedback Page",
      support_email: "support@feedbackpage.com",
      max_locations_per_user: 100,
      enable_user_registration: true,
      enable_email_verification: false,
      enable_social_login: true
    )
  end
end
