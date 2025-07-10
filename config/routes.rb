require "sidekiq/web"

Rails.application.routes.draw do
  devise_for :users
  root "home#index"

  resources :scans, only: [ :index, :show, :new, :create ] do
    member do
      get :download_report
    end
  end

  resources :vulnerabilities, only: [ :show ]

  # User API key management (singular resource since each user has only one)
  resource :api_key, only: [:show, :new, :create, :edit, :update, :destroy]

  namespace :admin do
    resources :api_keys
    mount Sidekiq::Web => "/sidekiq"
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end
