# frozen_string_literal: true

Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  namespace :api do
    get '/busgnag',  to: 'authentication#busgnag'

    scope '/user' do
      post '/register', to: 'authentication#register'
      post '/login', to: 'authentication#login'
      post '/reset-password', to: 'authentication#reset_password'
    end

    namespace :user do
      get '/me', action: :me
      get '/dashboard', action: :dashboard
      put '', action: :update
      put '/settings', action: :settings
    end

    get '/accounts', to: 'account#index'
    put '/accounts', to: 'account#update_amounts', as: :account_update_amounts
    resources :account, except: %i[new edit index]

    get '/bills', to: 'bill#index'
    resources :bill, except: %i[new edit index]
  end
end
