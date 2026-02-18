# frozen_string_literal: true

module Api
  module V1
    module Admin
      class UsersController < BaseController
        def index
          users = User.all.order(created_at: :desc)
          users = users.where("email LIKE ? OR name LIKE ?", "%#{params[:search]}%", "%#{params[:search]}%") if params[:search].present?
          users = users.where(plan: params[:plan]) if params[:plan].present?
          users = users.where(suspended: params[:status] == "suspended") if params[:status].present?
          page = (params[:page] || 1).to_i
          per = (params[:per_page] || 50).to_i
          total = users.count
          users = users.offset((page - 1) * per).limit(per)
          render json: {
            users: users.map { |u| admin_user_json(u) },
            pagination: { current_page: page, total_pages: (total.to_f / per).ceil, total_count: total, per_page: per }
          }, status: :ok
        end

        def show
          user = User.find(params[:id])
          render json: admin_user_json(user), status: :ok
        end

        def create
          user = User.new(create_user_params)
          if user.save
            render json: admin_user_json(user), status: :created
          else
            render json: { error: user.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def suspend
          user = User.find(params[:id])
          user.update!(suspended: true)
          render json: { success: true, message: "User suspended successfully" }, status: :ok
        end

        def activate
          user = User.find(params[:id])
          user.update!(suspended: false)
          render json: { success: true, message: "User activated successfully" }, status: :ok
        end

        def update
          user = User.find(params[:id])
          if params.key?(:admin) && params[:admin] == false
            if user.id == current_user.id
              return render json: { error: "Cannot revoke your own admin access." }, status: :unprocessable_entity
            end
            if User.where(admin: true).count == 1 && user.admin?
              return render json: { error: "Cannot revoke the last admin." }, status: :unprocessable_entity
            end
          end
          attrs = {}
          attrs[:admin] = params[:admin] if params.key?(:admin)
          attrs[:plan] = params[:plan] if params.key?(:plan)
          user.update!(attrs)
          render json: admin_user_json(user), status: :ok
        end

        def export
          require "csv"
          users = User.all.order(created_at: :desc)
          csv = CSV.generate(headers: true) do |row|
            row << %w[id email name business_name plan suspended created_at]
            users.each { |u| row << [u.id, u.email, u.name, u.business_name, u.plan, u.suspended, u.created_at.iso8601] }
          end
          send_data csv, filename: "users-#{Date.current.iso8601}.csv", type: "text/csv"
        end

        private

        def admin_user_json(u)
          {
            id: u.id.to_s,
            name: u.name,
            email: u.email,
            plan: u.plan,
            admin: u.admin?,
            status: u.suspended? ? "suspended" : "active",
            locations_count: u.locations.count,
            feedback_count: u.feedback_submissions.count,
            created_at: u.created_at.iso8601
          }
        end

        def create_user_params
          params.permit(:email, :name, :password, :plan).tap do |p|
            p[:plan] ||= "free"
          end
        end
      end
    end
  end
end
