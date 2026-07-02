Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "intake#show"

  resources :leads, only: [ :create ] do
    resources :messages,   only: [ :create ]
    resource  :selections, only: [ :create ]
    get "rooms/:room_key/render", to: "renders#show", as: :room_render
  end

  get "home", to: "home#show", as: :home

  get "admin", to: "admin#show", as: :admin

  get "reset", to: "demo#reset", as: :demo_reset
end
