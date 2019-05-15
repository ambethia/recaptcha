Rails.application.routes.draw do
  root to: redirect('/captchas')
  resources :captchas, only: [:index, :create]
  resources :users
end
