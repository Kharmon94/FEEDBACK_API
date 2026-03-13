# frozen_string_literal: true

class Location < ApplicationRecord
  has_one_attached :logo

  belongs_to :user
  has_many :feedback_submissions, dependent: :destroy
  has_many :feedback_page_events, dependent: :destroy
  has_many :suggestions, dependent: :nullify
  has_many :opt_ins, dependent: :destroy

  validates :name, presence: true
  validate :logo_url_not_base64
  before_validation :set_slug, on: :create

  def set_slug
    self.slug ||= "#{name.parameterize}-#{SecureRandom.hex(4)}" if name.present?
  end

  private

  def logo_url_not_base64
    return if logo_url.blank?

    if logo_url.to_s.start_with?("data:")
      errors.add(:logo_url, "Base64 images are not supported. Please upload your logo as a file or use a URL.")
      self.logo_url = nil
    end
  end
end
