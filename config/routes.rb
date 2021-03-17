Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  namespace :api do
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
    resources :account, except: [:new, :edit, :index]

    get '/bills', to: 'bill#index'
    #noinspection RailsParamDefResolve
    resources :bill, except: [:new, :edit, :index]
  end

end
