Rails.application.routes.draw do
  get "up" => "health#show", as: :rails_health_check

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

      resources :locations, only: %i[index show create update destroy]
      resources :feedback, only: %i[index]
      resources :suggestions, only: %i[index]
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
