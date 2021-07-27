# frozen_string_literal: true

class UserConfig < ApplicationRecord
  belongs_to :user

  monetize :income_cents

  enum day_type: { work_day: 0, all_days: 1 }
  enum income_option: { next_work_day: 0, previous_day: 1 }

  validates :day, presence: true, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 1,
    less_than_or_equal_to: lambda { |config|
                             config.day_type == :all_days.to_s ? 31 : 20
                           } # TODO: Check if is necessary (28 days max)
  }
  validates :day_type, presence: true, inclusion: { in: day_types.keys }
  validates :income_cents, numericality: { only_integer: true }
  validates :income_option, presence: true, inclusion: { in: income_options.keys }
  validates :work_in_holidays, inclusion: { in: [true, false] }

  def to_data
    {
      days_until_payment: days_until_payment,
      overhead_per_day_cents: overhead_per_day_cents,
      percentage_until_income: percentage_until_income,
      last_payment: last_payment,
      next_payment: next_payment,
      weekdays_until_payment: weekdays_until_payment,
      weekend_until_payment: weekend_until_payment
    }
  end

  def last_payment
    return @last_payment if @last_payment

    date = Date.today.to_date

    last_payment = date.change(day: day)

    last_payment -= 1.month if last_payment > date

    if last_payment.on_weekend?
      last_payment = if next_work_day?
                       last_payment.next_occurring :monday
                     elsif previous_day?
                       last_payment.prev_occurring :friday
                     end
    end

    @last_payment = last_payment
  end

  def next_payment
    return @next_payment if @next_payment

    date = Date.today.to_date

    next_payment = date.change(day: day)

    next_payment += 1.month if next_payment <= date

    if next_payment.on_weekend?
      next_payment = if next_work_day?
                       next_payment.next_occurring :monday
                     elsif previous_day?
                       next_payment.prev_occurring :friday
                     end
    end

    @next_payment = next_payment
  end

  def days_until_payment
    (next_payment - last_payment).to_i
  end

  def overhead_per_day_cents
    (user.total_amount_cents / days_until_payment)
  end

  def percentage_until_income
    last_payment = self.last_payment
    a = (Date.today - last_payment).to_d(2)
    b = (next_payment - last_payment).to_d(2)
    (a / b).round(2).to_f
  end

  def weekdays_until_payment
    calendar.business_days_between Date.today, next_payment
  end

  def weekend_until_payment
    days_until_payment - weekdays_until_payment
  end

  private

  def calendar
    Business::Calendar.new # handle the multiple holidays with https://github.com/gocardless/business
  end
end
