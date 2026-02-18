# frozen_string_literal: true

class ApplicationController < ActionController::API
  include CanCan::ControllerAdditions

  rescue_from ActiveRecord::RecordNotFound do
    render json: { error: "Not found" }, status: :not_found
  end

  rescue_from CanCan::AccessDenied do
    render json: { error: "Forbidden", message: "Insufficient permissions" }, status: :forbidden
  end

  def current_user
    nil
  end
end
