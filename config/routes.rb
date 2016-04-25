Rails.application.routes.draw do
  wash_out :users
  root to: 'visitors#index'
  devise_for :users, :controllers => { registrations: 'registrations' }
  resources :users
  mount Resque::Server, :at => "/resque"
end
