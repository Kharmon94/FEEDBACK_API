# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  layout "mailer"

  # Renders a design template from email-templates/ with {{variable}} substitution.
  # Supports {{#if var}}...{{/if}} for optional content.
  # Variables hash keys can be symbols or strings.
  def render_design_template(template_path, variables = {})
    base = Rails.root.join("email-templates")
    full_path = base.join("#{template_path}.html")
    raise "Design template not found: #{full_path}" unless File.exist?(full_path)

    html = File.read(full_path)
    vars = variables.transform_keys(&:to_s)

    # Process {{#if var}}...{{/if}} blocks first
    html = html.gsub(/\{\{#if\s+(\w+)\}\}(.*?)\{\{\/if\}\}/m) do
      key = Regexp.last_match(1)
      inner = Regexp.last_match(2)
      val = vars[key]
      val.present? ? inner : ""
    end

    # Replace {{key}} with values
    vars.each do |key, value|
      html = html.gsub("{{#{key}}}", value.to_s)
    end

    html.html_safe
  end
  after_action :set_default_from

  helper_method :mailer_logo_url, :mailer_help_url, :mailer_preferences_url, :recipient_first_name, :recipient_email

  def default_url_options
    uri = URI.parse(frontend_origin)
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
    normalize_origin(ENV["FRONTEND_ORIGIN"].presence || ENV["API_ORIGIN"].presence || "https://www.feedback-page.com")
  end

  def api_origin
    normalize_origin(ENV["API_ORIGIN"].presence || "https://www.feedback-page.com")
  end

  def normalize_origin(url)
    url = url.to_s.gsub(%r{/$}, "")
    url.include?("://") ? url : "https://#{url}"
  end

  def set_default_from
    mail.from = ENV["MAILER_FROM"].presence || (AdminSetting.instance.support_email rescue "noreply@feedback-page.com")
  end
end
