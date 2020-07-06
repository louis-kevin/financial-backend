class Account < ApplicationRecord
  validates :name, presence: true
  validates :amount, presence: true
  validates :color, presence: true, format: { with: /(0x)(?:[a-f0-9]{3}|[a-f0-9]{6})\b/ }

  monetize :amount_cents, allow_nil: false

  belongs_to :user
  has_many :bills
end
