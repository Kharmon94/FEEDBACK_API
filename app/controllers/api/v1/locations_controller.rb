# frozen_string_literal: true

module Api
  module V1
    class LocationsController < BaseController
      skip_before_action :authenticate_user!, only: [:show_public]
      before_action :set_location, only: %i[show update destroy]

      def index
        authorize! :read, Location
        locations = current_user.locations
        render json: { locations: locations.map { |l| location_json(l) } }, status: :ok
      end

      def show
        authorize! :read, @location
        render json: { location: location_json(@location) }, status: :ok
      end

      def create
        authorize! :create, Location
        location = current_user.locations.build(location_params.except(:logo))
        if location.save
          location.logo.attach(params[:logo]) if params[:logo].present?
          render json: { location: location_json(location) }, status: :created
        else
          render json: { error: location.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        authorize! :update, @location
        @location.logo.attach(params[:logo]) if params[:logo].present?
        if @location.update(location_params.except(:logo))
          render json: { location: location_json(@location) }, status: :ok
        else
          render json: { error: @location.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        authorize! :destroy, @location
        @location.destroy
        head :no_content
      end

      def show_public
        loc = Location.find_by(id: params[:id]) || Location.find_by(slug: params[:id])
        return head :not_found unless loc
        render json: { location: location_public_json(loc) }, status: :ok
      end

      private

      def set_location
        @location = current_user.locations.find(params[:id])
      end

      def location_params
        params.permit(:name, :logo_url, :logo, review_platforms: {})
      end

      def location_json(l)
        {
          id: l.id,
          name: l.name,
          slug: l.slug,
          logo_url: logo_url_for(l),
          review_platforms: l.review_platforms
        }
      end

      def location_public_json(l)
        {
          id: l.id,
          name: l.name,
          logo_url: logo_url_for(l),
          review_platforms: l.review_platforms
        }
      end

      def logo_url_for(loc)
        return loc.read_attribute(:logo_url) if loc.read_attribute(:logo_url).present?
        return nil unless loc.logo.attached?
        Rails.application.routes.url_helpers.rails_blob_url(loc.logo)
      end
    end
  end
end
