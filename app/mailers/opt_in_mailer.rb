# frozen_string_literal: true

class OptInMailer < ApplicationMailer
  # To business owner: new newsletter/opt-in signup
  def new_optin(opt_in)
    @opt_in = opt_in
    @location = opt_in.location
    @owner = @location&.user
    return if @location.blank? || @owner.blank?

    origin = frontend_origin
    variables = {
      customer_name: opt_in.name,
      customer_email: opt_in.email,
      customer_phone: opt_in.phone.presence || "Not provided",
      location_name: @location.name,
      signup_date: opt_in.created_at.strftime("%B %d, %Y"),
      view_optins_url: "#{origin}/dashboard?tab=opt-ins",
      export_url: "#{origin}/dashboard?tab=opt-ins"
    }
    html = render_design_template("feedback/new-optin", variables)
    mail(to: @owner.email, subject: "New newsletter signup for #{@location.name}") do |format|
      format.html { render html: html, layout: false }
    end
  end

  # To customer: confirmation after they opted in
  def optin_confirmation(opt_in)
    @opt_in = opt_in
    @location = opt_in.location
    return if @location.blank?

    # Unsubscribe URL - placeholder until location-specific opt-out is implemented
    unsubscribe_url = "#{frontend_origin}/email-preferences"

    variables = {
      business_name: @location.name,
      customer_name: opt_in.name,
      welcome_offer: nil,
      facebook_url: location_social_url(@location, "facebook"),
      instagram_url: location_social_url(@location, "instagram"),
      twitter_url: location_social_url(@location, "twitter"),
      business_address: @location.address.presence,
      business_phone: @location.phone.presence,
      business_email: @location.email.presence || AdminSetting.instance.support_email,
      unsubscribe_url: unsubscribe_url
    }
    # Template uses {{#if social_links}} - we don't have that var; individual URLs are used
    variables[:social_links] = "1" if [variables[:facebook_url], variables[:instagram_url], variables[:twitter_url]].any?(&:present?)

    html = render_design_template("customer/optin-confirmation", variables)
    mail(to: opt_in.email, subject: "Welcome to #{@location.name}'s newsletter!") do |format|
      format.html { render html: html, layout: false }
    end
  end

  private

  def location_social_url(location, platform)
    platforms = location.review_platforms || {}
    return nil unless platforms.is_a?(Hash)
    key = platforms.keys.find { |k| k.to_s.downcase.include?(platform) }
    val = platforms[key]
    val.is_a?(String) ? val : (val.is_a?(Hash) ? val["url"] : nil)
  end
end
