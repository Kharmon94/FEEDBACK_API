# frozen_string_literal: true

class FeedbackPageEvent < ApplicationRecord
  belongs_to :location

  validates :event_type, presence: true,
            inclusion: { in: %w[page_view star_click feedback_submit thankyou_view] }
end
