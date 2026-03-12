# frozen_string_literal: true

module Api
  module V1
    class OptInsController < BaseController
      skip_before_action :authenticate_user!, only: [:create]

      def index
        authorize! :read, OptIn
        scope = OptIn.joins(:location).where(locations: { user_id: current_user.id }).order(created_at: :desc)
        scope = scope.where(location_id: params[:location_id]) if params[:location_id].present?
        opt_ins = scope.to_a
        render json: { opt_ins: opt_ins.map { |o| opt_in_json(o) } }, status: :ok
      end

      def show
        opt_in = OptIn.joins(:location).find_by!(id: params[:id], locations: { user_id: current_user.id })
        authorize! :read, opt_in
        render json: { opt_in: opt_in_json(opt_in) }, status: :ok
      end

      def destroy
        opt_in = OptIn.joins(:location).find_by!(id: params[:id], locations: { user_id: current_user.id })
        authorize! :destroy, opt_in
        opt_in.destroy!
        head :no_content
      end

      def create
        authorize! :create, OptIn
        location = resolve_location_from_param(params[:location_id])
        return render json: { error: "Location not found" }, status: :not_found unless location

        opt_in = location.opt_ins.build(opt_in_params)
        if opt_in.save
          owner = location.user
          if owner.present? && AdminSetting.instance.respond_to?(:notify_on_new_optin) && AdminSetting.instance.notify_on_new_optin && owner.email_notifications_enabled?
            OptInMailer.new_optin(opt_in).deliver_later
          end
          OptInMailer.optin_confirmation(opt_in).deliver_later
          render json: { opt_in: opt_in_json(opt_in) }, status: :created
        else
          render json: { error: opt_in.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def opt_in_params
        params.permit(:name, :email, :phone, :rating)
      end

      def opt_in_json(o)
        {
          id: o.id,
          location_id: o.location_id,
          name: o.name,
          email: o.email,
          phone: o.phone,
          rating: o.rating,
          created_at: o.created_at.iso8601
        }
      end
    end
  end
end
