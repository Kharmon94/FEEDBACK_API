# frozen_string_literal: true

class Location < ApplicationRecord
  has_one_attached :logo

  belongs_to :user
  has_many :feedback_submissions, dependent: :destroy
  has_many :suggestions, dependent: :nullify
  has_many :opt_ins, dependent: :destroy

  validates :name, presence: true
  before_validation :set_slug, on: :create

  def set_slug
    self.slug ||= "#{name.parameterize}-#{SecureRandom.hex(4)}" if name.present?
  end
end
