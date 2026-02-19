# Routes updated 2026-02-19
# OMNIAUTH_APP must be defined before mount; load the initializer explicitly
# since routes may load before config/initializers on some environments (e.g. Railway).
require_relative "initializers/omniauth"

Rails.application.routes.draw do
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  get "up" => "health#show", as: :rails_health_check

  # Auth without /api/v1 prefix (for frontends that use base URL without path)
  # OmniAuth handles GET /auth/:provider and /auth/:provider/callback, /auth/failure only
  mount OMNIAUTH_APP, at: "auth", constraints: ->(req) {
    p = req.path
    return false unless req.get?
    p == "/auth/failure" || p.match?(%r{\A/auth/(?!sign_in|sign_up|me|password|confirm)([^/]+)(/callback)?\z})
  }
  post "auth/password", to: "api/v1/auth#request_password_reset"
  put "auth/password", to: "api/v1/auth#reset_password"
  post "auth/confirm/resend", to: "api/v1/auth#resend_confirmation"
  # Auth routes at root so host-only VITE_API_URL works for all flows
  get "auth/me", to: "api/v1/auth#me"
  post "auth/sign_in", to: "api/v1/auth#sign_in"
  post "auth/sign_up", to: "api/v1/auth#sign_up"

  namespace :api do
    namespace :v1 do
      get "up" => "health#show"

      # OmniAuth mounted so GET /api/v1/auth/google_oauth2 is handled (avoids 404 in API-only).
      # Only match OAuth paths, not auth/sign_in, auth/sign_up, auth/me.
      mount OMNIAUTH_APP, at: "auth", constraints: ->(req) {
        p = req.path
        p == "/api/v1/auth/failure" || p.match?(%r{\A/api/v1/auth/(?!sign_in|sign_up|me)([^/]+)(/callback)?\z})
      }

      post "auth/sign_in", to: "auth#sign_in"
      post "auth/sign_up", to: "auth#sign_up"
      post "auth/password", to: "auth#request_password_reset"
      put "auth/password", to: "auth#reset_password"
      get "auth/confirm", to: "auth#confirm_email"
      post "auth/confirm/resend", to: "auth#resend_confirmation"
      get "auth/me", to: "auth#me"
      get "auth/:provider/callback", to: "auth#omniauth_callback"
      get "auth/failure", to: "auth#failure"

      get "locations/public/:id", to: "locations#show_public", as: :location_public
      post "feedback", to: "feedback#create"
      post "suggestions", to: "suggestions#create"
      post "opt_ins", to: "opt_ins#create"

      resources :locations, only: %i[index show create update destroy]
      resources :feedback, only: %i[index]
      resources :suggestions, only: %i[index]
      get "opt_ins", to: "opt_ins#index"
      get "onboarding", to: "onboarding#show"
      put "onboarding", to: "onboarding#update"
      get "dashboard", to: "dashboard#show"
      get "export/feedback", to: "export#feedback"
      get "export/suggestions", to: "export#suggestions"

      get "plans", to: "plans#index"

      namespace :admin do
        get "dashboard", to: "dashboard#index"
        resources :users, only: %i[index show create update] do
          put :suspend, on: :member
          put :activate, on: :member
          get :export, on: :collection
        end
        resources :plans, only: %i[index show create update destroy] do
          get :usage, on: :member
          post :reassign, on: :member
        end
        resources :locations, only: %i[index show create] do
          get :export, on: :collection
        end
        resources :feedback, only: %i[index show] do
          get :export, on: :collection
        end
        get "analytics", to: "analytics#index"
        get "analytics/export", to: "analytics#export"
        resources :suggestions, only: %i[index show] do
          get :export, on: :collection
        end
        get "settings", to: "settings#show"
        put "settings", to: "settings#update"
      end
    end
  end
end
