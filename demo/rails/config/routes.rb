Rails.application.routes.draw do
  root to: redirect('/captchas')
  resources :captchas,    only: [:index, :create]
  resources :v3_captchas, only: [:index, :create] do
    collection do
      post :create_multi
    end
  end
  resources :users
end
