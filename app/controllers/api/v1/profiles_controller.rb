# frozen_string_literal: true

module Api
  module V1
    class ProfilesController < BaseController
      include StripeMode

      def show
        authorize! :read, current_user
        render json: profile_json(current_user), status: :ok
      end

      def update
        authorize! :update, current_user
        if profile_params.key?(:email) && profile_params[:email] != current_user.email
          handle_email_change
        else
          update_profile_only
        end
      end

      def destroy
        authorize! :update, current_user
        if current_user.provider.blank? && params[:password].blank?
          return render json: { error: "Password is required to delete your account." }, status: :unprocessable_entity
        end
        if current_user.provider.blank?
          unless current_user.valid_password?(params[:password])
            return render json: { error: "Password is incorrect." }, status: :unprocessable_entity
          end
        end

        sub_id = current_user.stripe_subscription_id
        if sub_id.present? && stripe_configured?
          begin
            Stripe::Subscription.cancel(sub_id, { api_key: stripe_api_key })
          rescue Stripe::StripeError => e
            Rails.logger.error "[Profile] Stripe cancel failed for user #{current_user.id}: #{e.message}"
            return render json: { error: "Could not cancel subscription. Please try again or contact support." }, status: :unprocessable_entity
          end
        end

        current_user.destroy
        head :no_content
      end

      def change_password
        authorize! :update, current_user
        if current_user.provider.present?
          return render json: { error: "Password cannot be changed for accounts signed in with Google." }, status: :unprocessable_entity
        end

        unless current_user.valid_password?(params[:current_password])
          return render json: { error: "Current password is incorrect." }, status: :unprocessable_entity
        end

        current_user.password = params[:password]
        if current_user.save
          render json: { message: "Password has been updated." }, status: :ok
        else
          render json: { error: current_user.errors.full_messages.join(". ") }, status: :unprocessable_entity
        end
      end

      private

      def profile_params
        params.permit(:name, :business_name, :email).to_h.compact
      end

      def profile_json(u)
        return nil if u.nil?
        {
          id: u.id,
          email: u.email,
          unconfirmed_email: u.unconfirmed_email.presence,
          name: u.name,
          business_name: u.business_name,
          provider: u.provider.presence
        }
      end

      def update_profile_only
        attrs = profile_params.except(:email)
        current_user.assign_attributes(attrs)
        if current_user.save
          render json: { profile: profile_json(current_user), user: user_json_for_auth(current_user) }, status: :ok
        else
          render json: { error: current_user.errors.full_messages.first }, status: :unprocessable_entity
        end
      end

      def handle_email_change
        new_email = profile_params[:email].to_s.strip.downcase
        if new_email.blank?
          return render json: { error: "Email can't be blank" }, status: :unprocessable_entity
        end
        if User.where.not(id: current_user.id).exists?(email: new_email)
          return render json: { error: "Email has already been taken." }, status: :unprocessable_entity
        end

        attrs = profile_params.except(:email)
        current_user.assign_attributes(attrs)
        current_user.unconfirmed_email = new_email

        if AdminSetting.instance.enable_email_verification
          if current_user.save(validate: false)
            current_user.send_confirmation_instructions_for_new_email(new_email)
            Rails.logger.info "[Profile] Email change: sent confirmation to #{new_email} for user #{current_user.id}"
            render json: {
              profile: profile_json(current_user.reload),
              message: "A confirmation link has been sent to your new email address. Please click it to complete the change."
            }, status: :ok
          else
            render json: { error: current_user.errors.full_messages.first }, status: :unprocessable_entity
          end
        else
          current_user.email = new_email
          current_user.unconfirmed_email = nil
          if current_user.save
            render json: { profile: profile_json(current_user), user: user_json_for_auth(current_user) }, status: :ok
          else
            render json: { error: current_user.errors.full_messages.first }, status: :unprocessable_entity
          end
        end
      end

      def user_json_for_auth(u)
        return nil if u.nil?
        ep = u.effective_plan
        trial_ends_at = (ep == "free" && u.created_at) ? (u.created_at + 30.days) : nil
        {
          id: u.id,
          email: u.email,
          name: u.name,
          business_name: u.business_name,
          plan: ep,
          admin: u.admin,
          created_at: u.created_at&.iso8601,
          trial_ends_at: trial_ends_at&.iso8601,
          has_payment_method: ep != "free"
        }
      end
    end
  end
end
