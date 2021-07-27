# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password

  include JwtAuthenticable

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }

  has_many :accounts, dependent: :destroy
  has_many :bills, through: :accounts

  alias_attribute :config, :user_config
  has_one :user_config, dependent: :destroy

  def generate_recovery_token!
    update reset_password_token: SecureRandom.urlsafe_base64(nil, false)
  end

  def configured?
    config.present? && config.id?
  end

  def total_amount_cents
    accounts.sum(&:total_amount_cents)
  end
end
