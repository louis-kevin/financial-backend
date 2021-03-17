require 'rails_helper'

RSpec.describe UserConfig, type: :model do
  describe '#last_payment' do
    it 'should return last year when in january' do
      user_config = create(:user_config, day: 15)

      allow(Date).to receive(:today) {
        Date.new(2021, 1, 1)
      }

      expect(user_config.last_payment).to eq Date.new(2020, 12, 15)
    end

    it 'should return current day when is in the day' do
      user_config = create(:user_config, day: 15)

      allow(Date).to receive(:today) {
        Date.new(2021, 1, 15)
      }

      expect(user_config.last_payment).to eq Date.new(2021, 1, 15)
    end

    context 'when last_payment day is in weekend' do
      before(:each) do
        @user_config = create(:user_config, day: 15)

        allow(Date).to receive(:today) {
          # november 15 2020 is a sunday
          Date.new(2020, 12, 1)
        }
      end
      it 'should return a day less when previous_day? is true' do
        @user_config.update income_option: :previous_day
        correct_date = Date.new(2020, 11, 13)
        expect(@user_config.last_payment).to eq correct_date
      end
      it 'should return a day after when next_work_day? is true' do
        @user_config.update income_option: :next_work_day
        correct_date = Date.new(2020, 11, 16)
        expect(@user_config.last_payment).to eq correct_date
      end
    end
  end
  describe '#next_payment' do
    it 'should return next year when in december' do
      user_config = create(:user_config, day: 15)

      allow(Date).to receive(:today) {
        Date.new(2020, 12, 18)
      }

      expect(user_config.next_payment).to eq Date.new(2021, 01, 15)
    end

    it 'should return next month when is in the configured day' do
      user_config = create(:user_config, day: 15)

      allow(Date).to receive(:today) {
        Date.new(2020, 12, 15)
      }

      expect(user_config.next_payment).to eq Date.new(2021, 01, 15)
    end

    context 'when next_payment day is in weekend' do
      before(:each) do
        @user_config = create(:user_config, day: 15)

        allow(Date).to receive(:today) {
          # november 15 2020 is a sunday
          Date.new(2020, 10, 16)
        }
      end
      it 'should return a day less when previous_day? is true' do
        @user_config.update income_option: :previous_day
        correct_date = Date.new(2020, 11, 13)
        expect(@user_config.next_payment).to eq correct_date
      end
      it 'should return a day after when next_work_day? is true' do
        @user_config.update income_option: :next_work_day
        correct_date = Date.new(2020, 11, 16)
        expect(@user_config.next_payment).to eq correct_date
      end
    end
  end
  describe '#days_until_payment' do
    it 'should return 7 days' do
      user_config = create(:user_config)
      allow(user_config).to receive(:last_payment) {
        Date.today
      }
      allow(user_config).to receive(:next_payment) {
        Date.today + 7.days
      }
      expect(user_config.days_until_payment).to eq 7
    end
  end
  describe '#overhead_per_day' do
    it 'should return 1 amount per day' do
      user_config = create(:user_config)
      allow(user_config).to receive(:days_until_payment) { 30 }
      allow(user_config.user).to receive(:total_amount_cents) { 30 }
      expect(user_config.overhead_per_day_cents).to eq 1
    end

    it 'should return 0 amount per day when user amount is 0' do
      user_config = create(:user_config)
      allow(user_config).to receive(:days_until_payment) { 30 }
      allow(user_config.user).to receive(:total_amount_cents) { 0 }
      expect(user_config.overhead_per_day_cents).to eq 0
    end
  end
  describe '#percentage_until_income' do
    it 'should return 0 when is in the configured day' do
      user_config = create(:user_config)
      allow(user_config).to receive(:last_payment) {
        Date.today
      }
      allow(user_config).to receive(:next_payment) {
        Date.today + 10.days
      }

      expect(user_config.percentage_until_income).to eq 0
    end

    it 'should return 90 when is in the previous configured day' do
      user_config = create(:user_config)
      allow(user_config).to receive(:last_payment) {
        Date.today - 9.days
      }
      allow(user_config).to receive(:next_payment) {
        Date.today + 1.day
      }

      expect(user_config.percentage_until_income).to eq 0.9
    end
  end
  describe '#weekdays_until_payment' do
    it 'should return 6 when is just a week from the configured day' do
      user_config = create(:user_config)
      allow(Date).to receive(:today) {
        Date.new(2021, 3, 15)
      }
      allow(user_config).to receive(:next_payment) {
        Date.new(2021, 3, 22)
      }

      expect(user_config.weekdays_until_payment).to eq 5
    end
  end

  describe "#weekend_until_payment" do
    it 'should return 6 when is just a week from the configured day' do
      user_config = create(:user_config)
      allow(Date).to receive(:today) {
        Date.new(2021, 3, 15)
      }
      allow(user_config).to receive(:next_payment) {
        Date.new(2021, 3, 22)
      }
      allow(user_config).to receive(:days_until_payment) {
        (Date.new(2021, 3, 22) - Date.new(2021, 3, 15)).to_i
      }

      expect(user_config.weekend_until_payment).to eq 2
    end
  end
end
