# frozen_string_literal: true

class UserMailer < ApplicationMailer
  def reset_password_instructions(user, raw_token)
    @user = user
    @reset_url = reset_password_url(raw_token)
    mail(to: user.email, subject: "Reset your password")
  end

  def welcome(user)
    @user = user
    @dashboard_url = "#{root_url}/dashboard"
    mail(to: user.email, subject: "Welcome to Feedback Page")
  end

  def account_suspended(user)
    @user = user
    mail(to: user.email, subject: "Your account has been suspended")
  end

  def account_activated(user)
    @user = user
    @dashboard_url = "#{root_url}/login"
    mail(to: user.email, subject: "Your account has been reactivated")
  end

  def plan_changed(user, previous_plan, new_plan)
    @user = user
    @previous_plan = previous_plan
    @new_plan = new_plan
    mail(to: user.email, subject: "Your plan has been updated")
  end

  def admin_created_account(user, temporary_password)
    @user = user
    @temporary_password = temporary_password
    @login_url = "#{root_url}/login"
    mail(to: user.email, subject: "Your Feedback Page account has been created")
  end

  def confirmation_instructions(user, raw_token)
    @user = user
    @confirm_url = confirm_email_url(raw_token)
    mail(to: user.email, subject: "Confirm your email address")
  end

  private

  def confirm_email_url(token)
    api_origin = (ENV["API_ORIGIN"].presence || "https://www.feedback-page.com").gsub(%r{/$}, "")
    api_origin = "https://#{api_origin}" unless api_origin.include?("://")
    "#{api_origin}/api/v1/auth/confirm?token=#{CGI.escape(token)}"
  end

  def reset_password_url(token)
    origin = (ENV["FRONTEND_ORIGIN"].presence || "https://www.feedback-page.com").gsub(%r{/$}, "")
    origin = "https://#{origin}" unless origin.include?("://")
    "#{origin}/reset-password?token=#{CGI.escape(token)}"
  end

  def root_url
    origin = (ENV["FRONTEND_ORIGIN"].presence || "https://www.feedback-page.com").gsub(%r{/$}, "")
    origin = "https://#{origin}" unless origin.include?("://")
    origin
  end
end
