# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    name { Faker::Name.unique.name }
    email { Faker::Internet.safe_email }
    password { Faker::Internet.password(min_length: 6) }
  end
end
