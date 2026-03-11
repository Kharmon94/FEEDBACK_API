# frozen_string_literal: true

class SuggestionMailer < ApplicationMailer
  def new_suggestion(suggestion)
    @suggestion = suggestion
    @location = suggestion.location
    @owner = @location&.user
    return if @location.blank? || @owner.blank?

    origin = frontend_origin
    variables = {
      business_name: @location.name,
      customer_name: suggestion.submitter_email.present? ? suggestion.submitter_email.split("@").first : "Anonymous",
      customer_email: suggestion.submitter_email.presence || "Not provided",
      suggestion_date: suggestion.created_at.strftime("%B %d, %Y"),
      suggestion_text: suggestion.content.to_s,
      view_suggestion_url: "#{origin}/dashboard?tab=feedback"
    }
    html = render_design_template("feedback/new-suggestion", variables)
    mail(to: @owner.email, subject: "New suggestion for #{@location.name}") do |format|
      format.html { render html: html, layout: false }
    end
  end
end
