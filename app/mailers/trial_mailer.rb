# frozen_string_literal: true

# Trial reminder emails. Call from scheduled job when trial end dates approach.
# Example: TrialMailer.trial_7_days_reminder(user).deliver_later
class TrialMailer < ApplicationMailer
  def trial_15_days_reminder(user)
    send_trial_reminder(user, "trial/trial-15-days", {
      business_name: business_name_for(user),
      feedback_count: user.try(:feedback_submissions)&.count.to_i.to_s,
      avg_rating: avg_rating_for(user),
      pricing_url: "#{frontend_origin}/pricing"
    })
  end

  def trial_7_days_reminder(user)
    send_trial_reminder(user, "trial/trial-7-days", {
      business_name: business_name_for(user),
      trial_end_date: trial_end_date_for(user),
      pricing_url: "#{frontend_origin}/pricing"
    })
  end

  def trial_3_days_reminder(user)
    send_trial_reminder(user, "trial/trial-3-days", {
      business_name: business_name_for(user),
      trial_end_date: trial_end_date_for(user),
      feedback_count: user.try(:feedback_submissions)&.count.to_i.to_s,
      pricing_url: "#{frontend_origin}/pricing"
    })
  end

  def trial_last_day_reminder(user)
    send_trial_reminder(user, "trial/trial-last-day", {
      business_name: business_name_for(user),
      feedback_count: user.try(:feedback_submissions)&.count.to_i.to_s,
      optin_count: OptIn.joins(location: :user).where(users: { id: user.id }).count.to_s,
      pricing_url: "#{frontend_origin}/pricing",
      starter_url: "#{frontend_origin}/pricing",
      professional_url: "#{frontend_origin}/pricing"
    })
  end

  def trial_expired(user)
    send_trial_reminder(user, "trial/trial-expired", {
      business_name: business_name_for(user),
      cancellation_date: trial_end_date_for(user),
      access_end_date: trial_end_date_for(user),
      deletion_date: (Date.current + 30.days).strftime("%B %d, %Y"),
      pricing_url: "#{frontend_origin}/pricing"
    })
  end

  private

  def send_trial_reminder(user, template_path, variables)
    html = render_design_template(template_path, variables)
    subject = template_subject(template_path)
    mail(to: user.email, subject: subject) do |format|
      format.html { render html: html, layout: false }
    end
  end

  def template_subject(path)
    case path
    when "trial/trial-15-days" then "Your trial is going great! 🚀"
    when "trial/trial-7-days" then "7 days left in your free trial"
    when "trial/trial-3-days" then "3 days left in your free trial"
    when "trial/trial-last-day" then "Your trial ends tomorrow"
    when "trial/trial-expired" then "Your trial has ended"
    else "Trial reminder"
    end
  end

  def business_name_for(user)
    user.name.presence || user.email.split("@").first
  end

  def trial_end_date_for(user)
    trial_end = if user.respond_to?(:trial_ends_at) && user.trial_ends_at.present?
      user.trial_ends_at
    elsif user.respond_to?(:plan) && user.plan == "free" && user.respond_to?(:created_at) && user.created_at.present?
      user.created_at + 30.days
    end
    trial_end ? trial_end.to_date.strftime("%B %d, %Y") : ""
  end

  def avg_rating_for(user)
    return "0" unless user.respond_to?(:feedback_submissions)
    subs = user.feedback_submissions
    return "0" if subs.empty?
    (subs.average(:rating) || 0).round(1).to_s
  end
end
