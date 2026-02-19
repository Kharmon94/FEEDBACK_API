# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # OAuth is handled by GoogleOauthController + User.from_omniauth, not Devise omniauthable.
  # Keeping omniauthable caused "Could not find a valid mapping for path" when OmniAuth failed.

  has_many :locations, dependent: :destroy
  has_many :feedback_submissions, through: :locations
  has_many :suggestions, through: :locations

  validates :email, presence: true, uniqueness: true

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_initialize.tap do |user|
      user.email = auth.info.email
      user.name = auth.info.name
      user.password = Devise.friendly_token[0, 20] if user.new_record?
      user.save!
    end
  end

  # Use our UserMailer for password reset (link to frontend)
  def send_reset_password_instructions_notification(raw_token)
    UserMailer.reset_password_instructions(self, raw_token).deliver_later
  end

  # Email verification (gated by AdminSetting.enable_email_verification)
  def confirmed?
    confirmed_at.present?
  end

  def send_confirmation_instructions
    raw = SecureRandom.urlsafe_base64(32)
    self.confirmation_token = Digest::SHA256.hexdigest(raw)
    self.confirmation_sent_at = Time.current
    save!(validate: false)
    UserMailer.confirmation_instructions(self, raw).deliver_later
    raw
  end

  def self.find_by_confirmation_token(raw_token)
    return nil if raw_token.blank?
    digest = Digest::SHA256.hexdigest(raw_token)
    find_by(confirmation_token: digest)
  end

  def confirm!
    self.confirmed_at = Time.current
    self.confirmation_token = nil
    self.confirmation_sent_at = nil
    save!(validate: false)
  end

  def email_notifications_enabled?
    return true unless has_attribute?(:email_notifications_enabled)
    self[:email_notifications_enabled] != false
  end

  def email_marketing_opted_out?
    return false unless has_attribute?(:email_marketing_opt_out)
    self[:email_marketing_opt_out] == true
  end

  def email_unsubscribe_token
    payload = { user_id: id, exp: 7.days.from_now.to_i }
    Rails.application.message_verifier(:email_unsubscribe).generate(payload)
  end
end
