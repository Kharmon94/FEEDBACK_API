# frozen_string_literal: true

class FeedbackSubmission < ApplicationRecord
  belongs_to :location

  validates :rating, presence: true, numericality: { only_integer: true, in: 1..5 }
end
