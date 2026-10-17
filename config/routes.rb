Rails.application.routes.draw do

  devise_for :users
  resources :recipe_imports, only: %i[index create], path: "import"
  namespace :admin do
    resources :recipes do
      post :detach, on: :member
    end
    resources :ingredients do
      post :detach, on: :member
    end
    resources :categories

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
