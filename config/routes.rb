Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "intake#show"

  resources :leads, only: [ :create ] do
    resource :approval, only: [ :create ]
    resources :messages, only: [ :create ]
  end

  get "home", to: "home#show", as: :home
end
