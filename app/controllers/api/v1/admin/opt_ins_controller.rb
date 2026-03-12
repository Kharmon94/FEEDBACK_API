# frozen_string_literal: true

module Api
  module V1
    module Admin
      class OptInsController < BaseController
        def index
          opt_ins = OptIn.includes(location: :user).order(created_at: :desc)
          if params[:location_id].present?
            loc = resolve_location_from_param(params[:location_id])
            opt_ins = loc ? opt_ins.where(location_id: loc.id) : opt_ins.where(location_id: nil)
          end
          if params[:user_id].present?
            usr = resolve_user_from_param(params[:user_id])
            opt_ins = usr ? opt_ins.joins(:location).where(locations: { user_id: usr.id }) : opt_ins.joins(:location).where(locations: { user_id: nil })
          end
          page = (params[:page] || 1).to_i
          per = (params[:per_page] || 50).to_i
          total = opt_ins.count
          opt_ins = opt_ins.offset((page - 1) * per).limit(per)
          render json: {
            opt_ins: opt_ins.map { |o| admin_opt_in_json(o) },
            pagination: { current_page: page, total_pages: (total.to_f / per).ceil, total_count: total, per_page: per }
          }, status: :ok
        end

        def show
          o = OptIn.find(params[:id])
          render json: admin_opt_in_json(o), status: :ok
        end

        def export
          require "csv"
          opt_ins = OptIn.includes(location: :user).order(created_at: :desc)
          if params[:location_id].present?
            loc = resolve_location_from_param(params[:location_id])
            opt_ins = loc ? opt_ins.where(location_id: loc.id) : opt_ins.where(location_id: nil)
          end
          if params[:user_id].present?
            usr = resolve_user_from_param(params[:user_id])
            opt_ins = usr ? opt_ins.joins(:location).where(locations: { user_id: usr.id }) : opt_ins.joins(:location).where(locations: { user_id: nil })
          end
          csv = CSV.generate(headers: true) do |row|
            row << %w[id name email phone rating location_id location_name user_id created_at]
            opt_ins.each do |o|
              row << [
                o.id,
                o.name,
                o.email,
                o.phone,
                o.rating,
                o.location_id,
                o.location&.name,
                o.location&.user_id,
                o.created_at.iso8601
              ]
            end
          end
          send_data csv, filename: "opt-ins-#{Date.current.iso8601}.csv", type: "text/csv"
        end

        private

        def admin_opt_in_json(o)
          {
            id: o.id.to_s,
            name: o.name,
            email: o.email,
            phone: o.phone,
            rating: o.rating,
            location_id: o.location_id&.to_s,
            location_public_id: o.location_id ? LocationIdObfuscator.encode(o.location_id) : nil,
            location_name: o.location&.name,
            user_id: o.location&.user_id&.to_s,
            user_public_id: o.location&.user_id ? UserIdObfuscator.encode(o.location.user_id) : nil,
            user_name: o.location&.user&.name,
            user_email: o.location&.user&.email,
            created_at: o.created_at.iso8601
          }
        end
      end
    end
  end
end
