Rails.application.routes.draw do
  get "up" => "health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      get "up" => "health#show"

      post "auth/sign_in", to: "auth#sign_in"
      post "auth/sign_up", to: "auth#sign_up"
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

      namespace :admin do
        get "dashboard", to: "dashboard#index"
        resources :users, only: %i[index show] do
          put :suspend, on: :member
          put :activate, on: :member
          get :export, on: :collection
        end
        resources :locations, only: %i[index show] do
          get :export, on: :collection
        end
        resources :feedback, only: %i[index show] do
          get :export, on: :collection
        end
        get "analytics", to: "analytics#index"
        get "analytics/export", to: "analytics#export"
        get "settings", to: "settings#show"
        put "settings", to: "settings#update"
      end
    end
  end
end
