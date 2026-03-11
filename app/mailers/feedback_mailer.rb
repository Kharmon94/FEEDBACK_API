# frozen_string_literal: true

class FeedbackMailer < ApplicationMailer
  def new_feedback(feedback_submission)
    @submission = feedback_submission
    @location = feedback_submission.location
    @owner = @location.user
    origin = frontend_origin
    dashboard = "#{origin}/dashboard"
    variables = {
      business_name: @location.name,
      rating: feedback_submission.rating.to_s,
      rating_stars: "⭐" * feedback_submission.rating,
      customer_name: feedback_submission.customer_name.presence || "Anonymous",
      customer_email: feedback_submission.customer_email.presence || "Not provided",
      customer_phone: feedback_submission.phone_number.presence || "Not provided",
      feedback_date: feedback_submission.created_at.strftime("%B %d, %Y at %I:%M %p"),
      comment: feedback_submission.comment.to_s,
      view_feedback_url: dashboard,
      mark_resolved_url: dashboard,
      notification_settings_url: "#{origin}/dashboard?tab=settings"
    }
    html = render_design_template("feedback/new-negative-feedback", variables)
    mail(to: @owner.email, subject: "New feedback for #{@location.name}") do |format|
      format.html { render html: html, layout: false }
    end
  end

  def contact_me_acknowledgment(feedback_submission)
    @submission = feedback_submission
    @location = feedback_submission.location
    variables = {
      business_name: @location.name,
      customer_name: feedback_submission.customer_name.presence,
      business_email: @location.email.presence || AdminSetting.instance.support_email,
      business_phone: @location.phone.presence,
      business_address: @location.address.presence
    }
    html = render_design_template("customer/feedback-confirmation", variables)
    mail(to: feedback_submission.customer_email, subject: "We received your feedback") do |format|
      format.html { render html: html, layout: false }
    end
  end
end
