Rails.application.routes.draw do
  root "landing#show"

  get "access", to: "access#new"
  post "access", to: "access#create"
  delete "access", to: "access#destroy"

  get "workspace", to: "workspace#show"
  resources :analysis_requests, only: :create do
    post :retry, on: :member
    patch :archive, on: :member
  end
  resources :briefs, only: :show do
    collection do
      get :archived
    end
    patch :archive, on: :member
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
