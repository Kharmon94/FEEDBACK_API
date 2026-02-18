# frozen_string_literal: true

module Api
  module V1
    module Admin
      class PlansController < BaseController
        def index
          plans = Plan.order(display_order: :asc, id: :asc)
          render json: { plans: plans.map { |p| admin_plan_json(p) } }, status: :ok
        end

        def show
          plan = Plan.find(params[:id])
          render json: admin_plan_json(plan), status: :ok
        end

        def create
          plan = Plan.new(plan_params)
          if plan.save
            render json: admin_plan_json(plan), status: :created
          else
            render json: { error: plan.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          plan = Plan.find(params[:id])
          if free_plan?(plan) && params.key?(:active) && params[:active] == false
            return render json: { error: "Cannot deactivate the free plan." }, status: :unprocessable_entity
          end

          replacement_slug = params[:replacement_slug]
          if params.key?(:active) && params[:active] == false
            users_count = User.where(plan: plan.slug).count
            if users_count.positive?
              if replacement_slug.blank?
                return render json: { error: "This plan has #{users_count} users. Provide replacement_slug to reassign before deactivating." }, status: :unprocessable_entity
              end
              replacement = find_replacement_plan(replacement_slug, current_slug: plan.slug)
              return if performed?
              reassign_users!(from_slug: plan.slug, to_slug: replacement.slug)
            end
          end

          if plan.update(plan_params)
            render json: admin_plan_json(plan), status: :ok
          else
            render json: { error: plan.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # Soft-delete by default: set active=false. Hard delete only when ?hard=true and no users reference it.
        def destroy
          plan = Plan.find(params[:id])
          return render json: { error: "Cannot delete the free plan." }, status: :unprocessable_entity if free_plan?(plan)

          users_count = User.where(plan: plan.slug).count
          replacement_slug = params[:replacement_slug]

          if users_count.positive?
            if replacement_slug.blank?
              return render json: { error: "This plan has #{users_count} users. Provide replacement_slug to reassign before deleting." }, status: :unprocessable_entity
            end
            replacement = find_replacement_plan(replacement_slug, current_slug: plan.slug)
            return if performed?
            reassign_users!(from_slug: plan.slug, to_slug: replacement.slug)
          end

          hard = ActiveModel::Type::Boolean.new.cast(params[:hard])
          if hard
            if users_count.positive?
              return render json: { error: "Cannot hard delete a plan that has users." }, status: :unprocessable_entity
            end
            plan.destroy!
            render json: { success: true }, status: :ok
          else
            plan.update!(active: false)
            render json: admin_plan_json(plan), status: :ok
          end
        end

        def usage
          plan = Plan.find(params[:id])
          users_count = User.where(plan: plan.slug).count
          render json: { plan_id: plan.id.to_s, slug: plan.slug, users_count: users_count }, status: :ok
        end

        def reassign
          plan = Plan.find(params[:id])
          return render json: { error: "Cannot reassign users from the free plan." }, status: :unprocessable_entity if free_plan?(plan)

          replacement_slug = params[:replacement_slug]
          replacement = find_replacement_plan(replacement_slug, current_slug: plan.slug)
          return if performed?
          updated = reassign_users!(from_slug: plan.slug, to_slug: replacement.slug)
          render json: { updated_users_count: updated }, status: :ok
        end

        private

        def free_plan?(plan)
          plan.slug == "free"
        end

        def find_replacement_plan(slug, current_slug:)
          if slug.blank?
            render json: { error: "replacement_slug is required" }, status: :unprocessable_entity
            return
          end
          if slug == current_slug
            render json: { error: "replacement_slug must be different" }, status: :unprocessable_entity
            return
          end
          replacement = Plan.find_by(slug: slug)
          unless replacement
            render json: { error: "Replacement plan not found" }, status: :unprocessable_entity
            return
          end
          unless replacement.active?
            render json: { error: "Replacement plan must be active" }, status: :unprocessable_entity
            return
          end
          replacement
        end

        def reassign_users!(from_slug:, to_slug:)
          ActiveRecord::Base.transaction do
            User.where(plan: from_slug).update_all(plan: to_slug)
          end
        end

        def admin_plan_json(p)
          {
            id: p.id.to_s,
            slug: p.slug,
            name: p.name,
            monthly_price_cents: p.monthly_price_cents,
            yearly_price_cents: p.yearly_price_cents,
            location_limit: p.location_limit,
            features: p.features,
            cta: p.cta,
            highlighted: p.highlighted,
            display_order: p.display_order,
            active: p.active
          }
        end

        def plan_params
          permitted = params.permit(
            :slug,
            :name,
            :monthly_price_cents,
            :yearly_price_cents,
            :location_limit,
            :cta,
            :highlighted,
            :display_order,
            :active,
            features: []
          ).to_h

          %i[monthly_price_cents yearly_price_cents location_limit display_order].each do |k|
            next unless permitted.key?(k)
            permitted[k] = permitted[k].to_i if permitted[k].is_a?(String) && permitted[k].match?(/\A-?\d+\z/)
          end

          %i[highlighted active].each do |k|
            next unless permitted.key?(k)
            permitted[k] = ActiveModel::Type::Boolean.new.cast(permitted[k])
          end

          permitted
        end
      end
    end
  end
end

