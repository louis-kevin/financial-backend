FactoryBot.define do
  factory :bill do
    account { create(:account) }
    amount { Faker::Number.decimal(l_digits: 2) }
    name { Faker::Name.first_name }
    payed { Faker::Boolean.boolean }
    payment_day { Faker::Number.between(from: 1, to: 31 ) }
    repetition_type { Bill.repetition_types.keys.sample }
  end
end
