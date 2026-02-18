# frozen_string_literal: true

class SuggestionMailer < ApplicationMailer
  def new_suggestion(suggestion)
    @suggestion = suggestion
    @location = suggestion.location
    @owner = @location&.user
    return if @location.blank? || @owner.blank?

    @suggestions_url = suggestions_url
    mail(to: @owner.email, subject: "New suggestion for #{@location.name}")
  end

  private

  def suggestions_url
    origin = (ENV["FRONTEND_ORIGIN"].presence || "https://www.feedback-page.com").gsub(%r{/$}, "")
    origin = "https://#{origin}" unless origin.include?("://")
    "#{origin}/dashboard"
  end
end
