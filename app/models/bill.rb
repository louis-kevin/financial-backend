class Bill < ApplicationRecord
  enum repetition_type: { once: 0, daily: 1, monthly: 2 }
  belongs_to :account
  has_one :user, through: :account

  monetize :amount_cents

  validates :amount_cents, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :repetition_type, presence: true, inclusion: { in: repetition_types.keys }
  validates :name, presence: true
  validates :payed, inclusion: { in: [true, false] }
  validates :payment_day, :allow_nil => true, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 1,
    less_than_or_equal_to: 31
  }

  validates_presence_of :payment_day, :if => :monthly?

  before_validation { self.payment_day = nil if daily? }
end
