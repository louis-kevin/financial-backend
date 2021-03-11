Rails.application.routes.draw do
  post "/graphql", to: "graphql#execute"
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  namespace :api do
    scope '/user' do
      post '/register', to: 'authentication#register'
      post '/login', to: 'authentication#login'
      post '/reset-password', to: 'authentication#reset_password'
    end

    namespace :user do
      get '/me', action: :me
      put '', action: :update
      put '/settings', action: :settings
    end

    get '/accounts', to: 'account#index'
    #noinspection RailsParamDefResolve
    resource :account, except: [:new, :edit], controller: :account

    get '/bills', to: 'bill#index'
    #noinspection RailsParamDefResolve
    resource :bill, except: [:new, :edit], controller: :bill
  end

end
