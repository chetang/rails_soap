Rails.application.routes.draw do
  wash_out :users
  root to: 'visitors#index'
  devise_for :users, :controllers => { registrations: 'registrations' }
  resources :users
  get '/add_item'          , to: 'users#add_item'
end
