# frozen_string_literal: true

class UserMailer < ApplicationMailer
  def new_reset_password
    @user = params[:user]
    mail(to: @user.email, subject: 'Esqueci minha senha - FinancialApp')
    @user.update reset_password_sent_at: DateTime.now
  end
end
