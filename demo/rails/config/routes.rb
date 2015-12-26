Rails.application.routes.draw do
  root to: "captcha#index"
  post "/captchas" => "captcha#create"
  resources :users
end
