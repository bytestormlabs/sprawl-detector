Rails.application.routes.draw do
  devise_for :users, controllers: {sessions: "sessions", registrations: "registrations"}
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"

  resources :findings
  resources :finding_summary, only: %w[index]
  resources :accounts

  get "/accounts/:id/validate", to: "accounts#validate"
end
