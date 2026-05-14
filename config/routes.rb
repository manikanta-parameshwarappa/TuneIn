Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"

  post "/signup", to: "auth#signup"
  post "/login", to: "auth#login"
  post "/refresh", to: "auth#refresh"
  delete "/logout", to: "auth#logout"

  get "/profile", to: "users#profile"
  patch "/profile", to: "users#update"

  resources :users do
    resources :playlists
    resources :likes
  end

  resources :artists do
    resources :albums
  end

  resources :albums do
    resources :songs
  end

  resources :songs do
    resources :likes
    collection do
      post :bulk_create
    end
  end

  resources :playlists do
    resources :playlist_songs
  end
end
