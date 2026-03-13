# Routes updated 2026-02-19
Rails.application.routes.draw do
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  get "up" => "health#show", as: :rails_health_check

  # OmniAuth callback (default /auth paths)
  get "auth/:provider/callback", to: "api/v1/google_oauth#callback"
  get "auth/google_oauth2", to: "api/v1/google_oauth#redirect_if_not_configured"

  # Auth without /api/v1 prefix (for frontends that use base URL without path)
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

      post "auth/sign_in", to: "auth#sign_in"
      post "auth/sign_up", to: "auth#sign_up"
      post "auth/password", to: "auth#request_password_reset"
      put "auth/password", to: "auth#reset_password"
      get "auth/confirm", to: "auth#confirm_email"
      post "auth/confirm/resend", to: "auth#resend_confirmation"
      get "auth/me", to: "auth#me"

      get "locations/public/:id", to: "locations#show_public", as: :location_public
      post "feedback", to: "feedback#create"
      post "feedback/events", to: "feedback_events#create"
      get "feedback/analytics", to: "feedback#analytics", defaults: { format: :json }
      post "suggestions", to: "suggestions#create"
      post "opt_ins", to: "opt_ins#create"

      resources :locations, only: %i[index show create update destroy]
      resources :feedback, only: %i[index]
      resources :suggestions, only: %i[index show destroy]
      resources :opt_ins, only: %i[index show destroy]
      get "onboarding", to: "onboarding#show"
      put "onboarding", to: "onboarding#update"
      get "dashboard", to: "dashboard#show"
      get "export/feedback", to: "export#feedback"
      get "export/suggestions", to: "export#suggestions"

      get "plans", to: "plans#index"

      post "checkout/create_session", to: "checkout#create_session"
      post "portal/create_session", to: "portal#create_session"
      post "webhooks/stripe", to: "webhooks/stripe#create"

      resource :email_preferences, only: %i[show update], path: "email-preferences" do
        get :unsubscribe, on: :collection
      end

      resource :profile, only: %i[show update], controller: "profiles"
      put "profile/password", to: "profiles#change_password"

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
        resources :opt_ins, only: %i[index show], path: "opt-ins" do
          get :export, on: :collection
        end
        get "settings", to: "settings#show"
        put "settings", to: "settings#update"
      end
    end
  end
end
