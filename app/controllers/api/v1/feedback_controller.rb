# frozen_string_literal: true

module Api
  module V1
    class FeedbackController < BaseController
      skip_before_action :authenticate_user!, only: [:create]

      def index
        authorize! :read, FeedbackSubmission
        submissions = FeedbackSubmission.joins(:location).where(locations: { user_id: current_user.id }).order(created_at: :desc)
        render json: { feedback: submissions.map { |f| feedback_json(f) } }, status: :ok
      end

      def create
        authorize! :create, FeedbackSubmission
        location = Location.find_by(id: params[:location_id]) || Location.find_by(slug: params[:location_id])
        return render json: { error: "Location not found" }, status: :not_found unless location
        submission = location.feedback_submissions.build(feedback_params)
        if submission.save
          if AdminSetting.instance.notify_on_new_feedback
            FeedbackMailer.new_feedback(submission).deliver_later
          end
          if submission.contact_me && submission.customer_email.present?
            FeedbackMailer.contact_me_acknowledgment(submission).deliver_later
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

      def feedback_json(f)
        {
          id: f.id,
          location_id: f.location_id,
          rating: f.rating,
          comment: f.comment,
          customer_name: f.customer_name,
          customer_email: f.customer_email,
          created_at: f.created_at.iso8601
        }
      end
    end
  end
end
