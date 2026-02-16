# frozen_string_literal: true

module Api
  module V1
    class OnboardingController < BaseController
      def show
        authorize! :read, :onboarding
        u = current_user
        render json: {
          business_name: u.business_name,
          name: u.name,
          logo_url: u.locations.first&.logo_url,
          review_platforms: u.locations.first&.review_platforms || {}
        }, status: :ok
      end

      def update
        authorize! :update, :onboarding
        current_user.update!(onboarding_params)
        loc = current_user.locations.first_or_initialize
        loc.name = current_user.business_name.presence || "Main"
        loc.logo_url = params[:logo_url] if params.key?(:logo_url)
        loc.review_platforms = params[:review_platforms].to_h if params.key?(:review_platforms)
        loc.save!
        render json: { user: { id: current_user.id, email: current_user.email, name: current_user.name, business_name: current_user.business_name, plan: current_user.plan } }, status: :ok
      end

      private

      def onboarding_params
        params.permit(:business_name, :name)
      end
    end
  end
end
