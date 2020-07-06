class UserConfig < ApplicationRecord
  belongs_to :user

  monetize :income_cents

  enum day_type: { work_day: 0, all_days: 1 }
  enum income_option: { next_work_day: 0, previous_day: 1 }

  validates :day, presence: true, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 1,
    less_than_or_equal_to: ->(config) { config.day_type == :all_days.to_s ? 31 : 20 }
  }
  validates :day_type, presence: true, inclusion: { in: day_types.keys }
  validates :income, numericality: true
  validates :income_option, presence: true, inclusion: { in: income_options.keys }
  validates :work_in_holidays, inclusion: { in: [true, false] }
end
