# frozen_string_literal: true

module Api
  module V1
    class FeedbackEventsController < ApplicationController
      skip_before_action :authenticate_user!

      def create
        location = Location.find_by(id: params[:location_id]) || Location.find_by(slug: params[:location_id])
        return head :not_found unless location

        event = location.feedback_page_events.build(
          event_type: params[:event_type].presence || "page_view",
          rating: params[:rating].presence && params[:rating].to_i
        )
        enrich_with_device_and_location!(event)
        event.save!
        head :created
      rescue ActiveRecord::RecordInvalid
        head :unprocessable_entity
      end

      private

      def enrich_with_device_and_location!(event)
        ua = request.user_agent.to_s
        if ua.present?
          client = DeviceDetector.new(ua)
          event.device_type = normalize_device_type(client.device_type)
        end

        ip = request.remote_ip.presence || request.env["HTTP_X_FORWARDED_FOR"]&.split(",")&.first&.strip
        if ip.present? && !ip.match?(/\A(127\.|::1|localhost)/)
          begin
            result = Geocoder.search(ip).first
            if result
              event.country = result.country_code.presence
              event.region = result.region.presence
            end
          rescue => e
            Rails.logger.warn "[FeedbackEvents] Geocoding failed for #{ip}: #{e.message}"
          end
        end
      end

      def normalize_device_type(type)
        return nil if type.blank?
        t = type.to_s.downcase
        return "mobile" if %w[smartphone feature_phone phablet].include?(t)
        return "tablet" if t == "tablet"
        return "desktop" if %w[desktop car_browser tv smart_display].include?(t)
        type.to_s
      end
    end
  end
end
