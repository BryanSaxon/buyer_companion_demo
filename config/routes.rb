Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "intake#show"

  resources :leads, only: [ :create ] do
    resources :messages,   only: [ :create ]
    resource  :selections, only: [ :create ]
  end

  get "home", to: "home#show", as: :home

  get "admin", to: "admin#show", as: :admin
end
