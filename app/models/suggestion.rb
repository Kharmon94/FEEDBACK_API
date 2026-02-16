# frozen_string_literal: true

class Suggestion < ApplicationRecord
  belongs_to :location, optional: true

  validates :content, presence: true
end
