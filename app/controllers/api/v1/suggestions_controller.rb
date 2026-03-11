# frozen_string_literal: true

module Api
  module V1
    class SuggestionsController < BaseController
      skip_before_action :authenticate_user!, only: [:create]

      def index
        authorize! :read, Suggestion
        suggestions = Suggestion.joins(:location).where(locations: { user_id: current_user.id }).order(created_at: :desc)
        render json: { suggestions: suggestions.map { |s| suggestion_json(s) } }, status: :ok
      end

      def show
        suggestion = Suggestion.joins(:location).find_by!(id: params[:id], locations: { user_id: current_user.id })
        authorize! :read, suggestion
        render json: { suggestion: suggestion_json(suggestion) }, status: :ok
      end

      def destroy
        suggestion = Suggestion.joins(:location).find_by!(id: params[:id], locations: { user_id: current_user.id })
        authorize! :destroy, suggestion
        suggestion.destroy!
        head :no_content
      end

      def create
        authorize! :create, Suggestion
        suggestion = Suggestion.new(suggestion_params)
        if suggestion.save
          owner = suggestion.location&.user
          if owner.present? && AdminSetting.instance.notify_on_new_suggestion && owner.email_notifications_enabled?
            SuggestionMailer.new_suggestion(suggestion).deliver_later
          end
          render json: { suggestion: suggestion_json(suggestion) }, status: :created
        else
          render json: { error: suggestion.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def suggestion_params
        params.permit(:content, :submitter_email, :location_id)
      end

      def suggestion_json(s)
        {
          id: s.id,
          content: s.content,
          submitter_email: s.submitter_email,
          location_id: s.location_id,
          created_at: s.created_at.iso8601
        }
      end
    end
  end
end
