# frozen_string_literal: true

module Api
  module V1
    class FeedbackController < BaseController
      skip_before_action :authenticate_user!, only: [:create]

      def analytics
        authorize! :read, FeedbackSubmission
        location_ids = current_user.locations.pluck(:id)
        events = FeedbackPageEvent.where(location_id: location_ids)
        submissions = FeedbackSubmission.where(location_id: location_ids)

        page_views = events.where(event_type: "page_view").count
        star_clicks = events.where(event_type: "star_click").count
        feedback_submits = submissions.count

        device_breakdown = events.where(event_type: "page_view")
                                .group("COALESCE(device_type, 'unknown')")
                                .count

        top_countries = events.where(event_type: "page_view")
                              .where.not(country: [nil, ""])
                              .group(:country)
                              .order("count_all DESC")
                              .limit(10)
                              .count

        render json: {
          funnel: { page_views: page_views, star_clicks: star_clicks, submissions: feedback_submits },
          device_breakdown: device_breakdown,
          top_countries: top_countries
        }, status: :ok
      end

      def index
        authorize! :read, FeedbackSubmission
        submissions = FeedbackSubmission.joins(:location).includes(:location).where(locations: { user_id: current_user.id }).order(created_at: :desc)
        render json: { feedback: submissions.map { |f| feedback_json(f) } }, status: :ok
      end

      def create
        authorize! :create, FeedbackSubmission
        location = Location.find_by(id: params[:location_id]) || Location.find_by(slug: params[:location_id])
        return render json: { error: "Location not found" }, status: :not_found unless location
        submission = location.feedback_submissions.build(feedback_params)
        enrich_with_device_and_location!(submission)
        if submission.save
          owner = submission.location.user
          if AdminSetting.instance.notify_on_new_feedback && owner.email_notifications_enabled? && submission.rating <= 3
            FeedbackMailer.new_feedback(submission).deliver_later
            Rails.logger.info "[Feedback] Sent new_feedback email to #{owner.email}"
          end
          if submission.contact_me && submission.customer_email.present?
            FeedbackMailer.contact_me_acknowledgment(submission).deliver_later
            Rails.logger.info "[Feedback] Sent contact_me_acknowledgment to #{submission.customer_email}"
          end
          render json: { feedback: feedback_json(submission) }, status: :created
        else
          render json: { error: submission.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def feedback_params
        params.permit(:rating, :comment, :customer_name, :customer_email, :phone_number, :contact_me)
      end

      def enrich_with_device_and_location!(submission)
        ua = request.user_agent.to_s
        if ua.present?
          client = DeviceDetector.new(ua)
          submission.device_type = normalize_device_type(client.device_type)
        end

        ip = request.remote_ip.presence || request.env["HTTP_X_FORWARDED_FOR"]&.split(",")&.first&.strip
        if ip.present? && !ip.match?(/\A(127\.|::1|localhost)/)
          begin
            result = Geocoder.search(ip).first
            if result
              submission.country = result.country_code.presence
              submission.region = result.region.presence
            end
          rescue => e
            Rails.logger.warn "[Feedback] Geocoding failed for #{ip}: #{e.message}"
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

      def feedback_json(f)
        {
          id: f.id,
          location_id: f.location_id,
          location_name: f.location&.name,
          rating: f.rating,
          comment: f.comment,
          customer_name: f.customer_name,
          customer_email: f.customer_email,
          created_at: f.created_at.iso8601,
          device_type: f.device_type.presence,
          country: f.country.presence,
          region: f.region.presence
        }
      end
    end
  end
end
