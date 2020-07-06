module Api
  class AuthenticationController < Api::ApplicationController
    skip_before_action :authenticate_request

    def login
      user = User.find_by(email: authenticate_params[:email])

      return invalid_messages email: "Usuário não encontrado" unless user

      return invalid_messages password: "Senha inválida" unless user.authenticate(authenticate_params[:password])

      render json: user_as_json(user)
    end

    def register
      user = User.new(register_params)

      return invalid_messages(user.errors) unless user.save

      render json: user_as_json(user)
    end

    def reset_password
      render_json

      user = User.find_by(authenticate_params)

      return unless user

      user.generate_recovery_token!

      UserMailer.with(user: user).new_reset_password.deliver_later
    end

    private

    def user_as_json(user, token = true)
      data = user.as_json(only: [:id, :name, :email])

      data.merge! token: user.generate_jwt_token if token

      data
    end

    def authenticate_params
      params.permit(:email, :password)
    end

    def register_params
      params.permit(:email, :password, :name)
    end

    def reset_password_params
      params.permit(:email)
    end
  end
end