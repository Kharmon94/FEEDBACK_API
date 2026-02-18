# frozen_string_literal: true

class FeedbackMailer < ApplicationMailer
  def new_feedback(feedback_submission)
    @submission = feedback_submission
    @location = feedback_submission.location
    @owner = @location.user
    @feedback_url = feedback_url
    mail(to: @owner.email, subject: "New feedback for #{@location.name}")
  end

  def contact_me_acknowledgment(feedback_submission)
    @submission = feedback_submission
    @location = feedback_submission.location
    mail(to: feedback_submission.customer_email, subject: "We received your feedback")
  end

  private

  def feedback_url
    origin = (ENV["FRONTEND_ORIGIN"].presence || "https://www.feedback-page.com").gsub(%r{/$}, "")
    origin = "https://#{origin}" unless origin.include?("://")
    "#{origin}/dashboard"
  end
end
