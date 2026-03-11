# frozen_string_literal: true

class UserMailer < ApplicationMailer
  def reset_password_instructions(user, raw_token)
    @user = user
    reset_url = reset_password_url(raw_token)
    Rails.logger.info "[UserMailer] Sending reset_password_instructions to #{user.email}, reset_url=#{reset_url}"
    variables = {
      user_name: user.name.presence || user.email.split("@").first,
      reset_url: reset_url
    }
    html = render_design_template("auth/password-reset", variables)
    mail(to: user.email, subject: "Reset Your Password") do |format|
      format.html { render html: html, layout: false }
    end
  end

  def welcome(user)
    @user = user
    variables = {
      business_name: user.name.presence || user.email.split("@").first,
      dashboard_url: "#{frontend_origin}/dashboard",
      help_url: "#{frontend_origin}/help"
    }
    html = render_design_template("auth/welcome", variables)
    mail(to: user.email, subject: "Welcome to Feedback Page! 🎉") do |format|
      format.html { render html: html, layout: false }
    end
  end

  def account_suspended(user)
    @user = user
    mail(to: user.email, subject: "Your account has been suspended")
  end

  def account_activated(user)
    @user = user
    @dashboard_url = "#{frontend_origin}/login"
    mail(to: user.email, subject: "Your account has been reactivated")
  end

  def plan_changed(user, previous_plan_slug, new_plan_slug)
    @user = user
    old_plan = Plan.find_by(slug: previous_plan_slug)
    new_plan = Plan.find_by(slug: new_plan_slug)
    is_upgrade = new_plan && old_plan && (new_plan.display_order > old_plan.display_order)

    template_path = is_upgrade ? "billing/subscription-upgraded" : "billing/subscription-downgraded"
    variables = {
      business_name: user.name.presence || user.email.split("@").first,
      new_plan_name: new_plan&.name || new_plan_slug.to_s.titleize,
      old_plan_name: old_plan&.name || previous_plan_slug.to_s.titleize,
      old_price: format_plan_price(old_plan),
      new_price: format_plan_price(new_plan),
      prorated_amount: "",
      next_billing_date: "",
      feature_1: new_plan&.features&.first || "",
      feature_2: new_plan&.features&.second || "",
      feature_3: new_plan&.features&.third || "",
      effective_date: Date.current.strftime("%B %d, %Y"),
      credit_amount: "",
      limitation_1: "",
      limitation_2: "",
      dashboard_url: "#{frontend_origin}/dashboard",
      billing_url: "#{frontend_origin}/dashboard?tab=billing",
      upgrade_url: "#{frontend_origin}/pricing"
    }

    html = render_design_template(template_path, variables)
    subject = is_upgrade ? "You've upgraded your plan!" : "Your plan has been updated"
    mail(to: user.email, subject: subject) do |format|
      format.html { render html: html, layout: false }
    end
  end

  def admin_created_account(user, temporary_password)
    @user = user
    @temporary_password = temporary_password
    @login_url = "#{frontend_origin}/login"
    mail(to: user.email, subject: "Your Feedback Page account has been created")
  end

  def confirmation_instructions(user, raw_token)
    @user = user
    verification_url = confirm_email_url(raw_token)
    variables = { verification_url: verification_url }
    html = render_design_template("auth/email-verification", variables)
    mail(to: user.email, subject: "Verify Your Email Address") do |format|
      format.html { render html: html, layout: false }
    end
  end

  private

  def confirm_email_url(token)
    "#{api_origin}/api/v1/auth/confirm?token=#{CGI.escape(token)}"
  end

  def reset_password_url(token)
    "#{frontend_origin}/reset-password?token=#{CGI.escape(token)}"
  end

  def format_plan_price(plan)
    return "Free" if plan.nil? || (plan.monthly_price_cents.to_i.zero? && plan.yearly_price_cents.to_i.zero?)
    return "$#{plan.monthly_price_cents / 100}/month" if plan.monthly_price_cents.to_i.positive?
    return "$#{plan.yearly_price_cents / 100}/year" if plan.yearly_price_cents.to_i.positive?
    "Contact for pricing"
  end
end
