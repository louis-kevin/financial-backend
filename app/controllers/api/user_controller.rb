class Api::UserController < Api::ApplicationController
  before_action :check_password, only: :update

  def dashboard; end

  def me
    render_json user_as_json current_user
  end

  def update
    data = update_params

    data[:password] = @password if @password.present?

    current_user.assign_attributes data

    return invalid_messages(current_user.errors) unless current_user.valid?

    current_user.save

    render_json user_as_json current_user
  end

  def settings
    config = current_user.config.presence || UserConfig.new
    config.assign_attributes(settings_params)
    config.user = current_user

    return invalid_messages(config.errors) unless config.save

    render_json config
  end

  private

  def user_as_json(user)
    user.as_json(only: [:id, :name, :email])
  end

  def check_password
    return if params[:old_password].blank?

    unless current_user.authenticate(params[:old_password])
      return current_user.errors.add(:old_password, 'Senha inválida')
    end

    @password = params[:new_password]
  end

  def update_params
    params.permit(:name, :email)
  end

  def settings_params
    params.permit(:day, :day_type, :income, :income_option, :work_in_holidays)
  end
end
