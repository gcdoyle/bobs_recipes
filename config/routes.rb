Rails.application.routes.draw do

  devise_for :users
  namespace :admin do
    resources :recipes
    resources :ingredients
    resources :categories

    resource :recipes, :ingredients do
      member do
        get ":id/detach" => :detach
      end
    end

    resource :recipes, :ingredients do
      member do
        post "detach" => :detach
      end
    end

    root to: "recipes#index"
  end

  controller :application do
    get 'search' => :search
  end

  resources :ingredients
  resources :recipes
  resources :categories

  root to: "categories#index"

end
