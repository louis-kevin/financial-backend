class Account < ApplicationRecord
  validates :name, presence: true
  validates :amount_cents, presence: true, numericality: { only_integer: true }
  validates :color, presence: true, format: { with: /(0x)(?:[a-f0-9]{8}|[a-f0-9]{6})\b/ }

  monetize :amount_cents, allow_nil: false

  belongs_to :user
  has_many :bills, dependent: :destroy

  def total_amount_cents
    (amount_cents - bills.where(payed: false).sum(:amount_cents))
  end
end
