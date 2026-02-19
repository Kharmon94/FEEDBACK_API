# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  layout "mailer"
  after_action :set_default_from

  helper_method :mailer_logo_url, :mailer_help_url, :mailer_preferences_url, :recipient_first_name, :recipient_email

  def default_url_options
    origin = ENV["FRONTEND_ORIGIN"].presence || ENV["API_ORIGIN"].presence || "https://www.feedback-page.com"
    origin = "https://#{origin}" unless origin.include?("://")
    uri = URI.parse(origin)
    { host: uri.host, protocol: uri.scheme }
  end

  def mailer_logo_url
    "#{frontend_origin}/logo.png"
  end

  def mailer_help_url
    "#{frontend_origin}/help"
  end

  def mailer_preferences_url
    "#{frontend_origin}/email-preferences"
  end

  def recipient_first_name
    return @recipient_first_name if defined?(@recipient_first_name) && @recipient_first_name.present?
    u = instance_variable_get(:@user) || instance_variable_get(:@owner)
    if u.respond_to?(:name) && u.name.present?
      u.name.split(/\s+/).first
    elsif u.respond_to?(:email) && u.email.present?
      u.email.split("@").first.tr(".", " ").titleize
    else
      sub = instance_variable_get(:@submission)
      if sub.respond_to?(:customer_name) && sub.customer_name.present?
        sub.customer_name.split(/\s+/).first
      else
        "there"
      end
    end
  end

  def recipient_email
    # Derive from instance variables; do NOT use mail.to during layout render
    # (mail may not be fully initialized, causing errors in collect_responses_from_templates)
    u = instance_variable_get(:@user) || instance_variable_get(:@owner)
    return u.email.to_s if u.present? && u.respond_to?(:email) && u.email.present?

    sub = instance_variable_get(:@submission)
    return sub.customer_email.to_s if sub.present? && sub.respond_to?(:customer_email) && sub.customer_email.present?

    ""
  end

  private

  def frontend_origin
    origin = (ENV["FRONTEND_ORIGIN"].presence || ENV["API_ORIGIN"].presence || "https://www.feedback-page.com").to_s.gsub(%r{/$}, "")
    origin.include?("://") ? origin : "https://#{origin}"
  end

  def set_default_from
    mail.from = ENV["MAILER_FROM"].presence || (AdminSetting.instance.support_email rescue "noreply@feedback-page.com")
  end
end
