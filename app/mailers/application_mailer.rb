# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  layout "mailer"
  after_action :set_default_from

  def default_url_options
    origin = ENV["FRONTEND_ORIGIN"].presence || ENV["API_ORIGIN"].presence || "https://www.feedback-page.com"
    origin = "https://#{origin}" unless origin.include?("://")
    uri = URI.parse(origin)
    { host: uri.host, protocol: uri.scheme }
  end

  private

  def set_default_from
    mail.from = ENV["MAILER_FROM"].presence || (AdminSetting.instance.support_email rescue "noreply@feedback-page.com")
  end
end
