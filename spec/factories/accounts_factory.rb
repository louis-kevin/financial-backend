# frozen_string_literal: true

FactoryBot.define do
  factory :account do
    name { Faker::Name.first_name }
    color { Faker::Color.hex_color.gsub('#', '0x') }
    amount { Faker::Number.decimal(l_digits: 2) }
    user { create(:user) }
  end
end
