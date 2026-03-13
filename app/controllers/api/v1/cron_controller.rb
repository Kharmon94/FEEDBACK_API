# frozen_string_literal: true

module Api
  module V1
    class CronController < ApplicationController
      skip_before_action :verify_authenticity_token
      before_action :verify_cron_secret

      def trial_reminders
        sent = { "15_days" => 0, "7_days" => 0, "3_days" => 0, "last_day" => 0, "expired" => 0 }
        now = Time.current
        today_end = now.end_of_day

        # Free plan users in app-side trial (no Stripe subscription yet)
        users = User.where(plan: "free")
                   .where(suspended: false)
                   .where("email IS NOT NULL AND email != ''")
                   .where(stripe_subscription_id: [nil, ""])

        users.find_each do |user|
          trial_end = user.created_at + 30.days
          next if trial_end > now + 16.days # trial hasn't started meaningful countdown

          days_remaining = ((trial_end - now) / 1.day).ceil

          if days_remaining == 15
            TrialMailer.trial_15_days_reminder(user).deliver_later
            sent["15_days"] += 1
          elsif days_remaining == 7
            TrialMailer.trial_7_days_reminder(user).deliver_later
            sent["7_days"] += 1
          elsif days_remaining == 3
            TrialMailer.trial_3_days_reminder(user).deliver_later
            sent["3_days"] += 1
          elsif days_remaining == 1
            TrialMailer.trial_last_day_reminder(user).deliver_later
            sent["last_day"] += 1
          elsif days_remaining <= 0
            TrialMailer.trial_expired(user).deliver_later
            sent["expired"] += 1
          end
        end

        Rails.logger.info "[Cron] Trial reminders sent: #{sent.inspect}"
        render json: { success: true, sent: sent }, status: :ok
      end

      private

      def verify_cron_secret
        secret = ENV["CRON_SECRET"].presence
        if secret.blank?
          return if Rails.env.development? || Rails.env.test?
          head :unauthorized and return
        end

        provided = request.headers["Authorization"]&.sub(/\ABearer\s+/i, "")&.strip ||
                   request.params["secret"]
        unless provided.present? && ActiveSupport::SecurityUtils.secure_compare(secret, provided)
          head :unauthorized
        end
      end
    end
  end
end
