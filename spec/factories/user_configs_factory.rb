FactoryBot.define do
  factory :user_config do
    user { create(:user) }
    day_type { UserConfig.day_types.keys.sample }
    day { Faker::Number.between(from: 1, to: day_type == :all_days.to_s ? 31 : 20) }
    income_option { UserConfig.income_options.keys.sample }
    income { Faker::Number.decimal(l_digits: 2) }
    work_in_holidays { Faker::Boolean.boolean }
  end
end
