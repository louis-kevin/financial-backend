require 'rails_helper'

RSpec.describe "Api::User", type: :request do
  describe 'PUT #update' do
    before(:each) do
      @user = create(:user, password: 12345678.to_s)
      @other_user = build(:user)

      @data = {
        name: @other_user.name,
        email: @other_user.email
      }
    end

    it 'should update name and email data' do
      put_with_token api_user_url, @data

      expect(response).to have_http_status(:ok)

      data = JSON.parse(response.body)

      expect(data).to include "name", "email", "id"
      expect(data["name"]).to eq @data[:name]
      expect(data["email"]).to eq @data[:email]
      expect(data["id"]).to eq @user.id

      expect(data["name"]).not_to eq @user.name
      expect(data["email"]).not_to eq @user.email

      @user.reload

      expect(data["name"]).to eq @user.name
      expect(data["email"]).to eq @user.email
    end

    it 'should update the password' do
      @data[:old_password] = 12345678
      @data[:new_password] = 87654321

      put_with_token api_user_url, @data.except(:name, :email)

      expect(response).to have_http_status(:ok)

      @user.reload

      expect(@user.authenticate(@data[:new_password])).to be_truthy
    end

    context 'should respond with error' do
      it 'when old password is wrong' do
        @data[:old_password] = 'wrong_password'
        @data[:new_password] = 87654321

        put_with_token api_user_url, @data.except(:name, :email)

        expect(response).to have_http_status(:ok)

        @user.reload

        expect(@user.authenticate(@data[:new_password])).to be_falsey
      end

      context 'when email is invalid' do
        it 'because already exists' do
          new_user = create(:user)
          @data[:email] = new_user.email
          old_email = @user.email

          put_with_token api_user_url, @data

          expect(response).to have_http_status(:unprocessable_entity)

          data = JSON.parse(response.body)

          expect(data).to include "email"

          @user.reload

          expect(old_email).to eq @user.email
        end
        it 'because is empty' do
          @data[:email] = ''
          old_email = @user.email

          put_with_token api_user_url, @data

          expect(response).to have_http_status(:unprocessable_entity)

          data = JSON.parse(response.body)

          expect(data).to include "email"

          @user.reload

          expect(old_email).to eq @user.email
        end
      end
      context 'when name is invalid' do
        it 'because is empty' do
          @data[:name] = ''
          old_name = @user.name

          put_with_token api_user_url, @data

          expect(response).to have_http_status(:unprocessable_entity)

          data = JSON.parse(response.body)

          expect(data).to include "name"

          @user.reload

          expect(old_name).to eq @user.name
        end
      end

    end
  end

  describe 'PUT #settings' do
    before(:each) do
      @user = create(:user)
      @user_config = build(:user_config, user: @user)
      @day_list = (1..(@user_config.all_days? ? 20 : 31))
    end
    context 'should save and respond with user config data' do
      it "when creating" do
        @data = {
          day: @user_config.day,
          day_type: @user_config.day_type,
          income: @user_config.income,
          income_option: @user_config.income_option,
          work_in_holidays: @user_config.work_in_holidays
        }

        expect(@user.configured?).to be_falsey

        put_with_token api_user_settings_url, @data

        expect(response).to have_http_status(:ok)

        expect(@user.reload.configured?).to be_truthy

        data = JSON.parse(response.body)
        expect(data).to include "day", "day_type", "income_cents", "income_option", "work_in_holidays"
        expect(data["day"]).to eq @data[:day]
        expect(data["day_type"]).to eq @data[:day_type].to_s
        expect(data["income_cents"]).to eq @data[:income].cents
        expect(data["income_option"]).to eq @data[:income_option].to_s
        expect(data["work_in_holidays"]).to eq @data[:work_in_holidays]
      end

      it "when updating", retry: 5 do
        @user_config.save
        expect(@user.configured?).to be_truthy


        @data = {
          day: @day_list.reject { |i| i == @user_config.day }.sample,
          day_type: @user_config.all_days? ? :work_day : :all_days,
          income: @user_config.income.to_f + 1,
          income_option: @user_config.next_work_day? ? :previous_day : :next_work_day,
          work_in_holidays: !@user_config.work_in_holidays
        }

        put_with_token api_user_settings_url, @data


        expect(response).to have_http_status(:ok)

        data = JSON.parse(response.body)
        expect(data).to include "day", "day_type", "income_cents", "income_option", "work_in_holidays"

        expect(data["day"]).not_to eq @user_config.day
        expect(data["day_type"]).not_to eq @user_config.day_type
        expect(data["income_cents"].to_f).not_to eq @user_config.income.cents
        expect(data["income_option"]).not_to eq @user_config.income_option.to_s
        expect(data["work_in_holidays"]).not_to eq @user_config.work_in_holidays

        expect(data["day"]).to eq @data[:day]
        expect(data["day_type"]).to eq @data[:day_type].to_s
        expect(data["income_cents"]).to eq @data[:income] * 100
        expect(data["income_option"]).to eq @data[:income_option].to_s
        expect(data["work_in_holidays"]).to eq @data[:work_in_holidays]

        @user_config.reload

        expect(data["day"]).to eq @user_config.day
        expect(data["day_type"]).to eq @user_config.day_type
        expect(data["income_cents"]).to eq @user_config.income.cents
        expect(data["income_option"]).to eq @user_config.income_option.to_s
        expect(data["work_in_holidays"]).to eq @user_config.work_in_holidays


      end
      it "when creating without income" do
        @data = {
          day: @day_list.reject { |i| i == @user_config.day }.sample,
          day_type: @user_config.all_days? ? :work_day : :all_days,
          income_option: @user_config.next_work_day? ? :previous_day : :next_work_day,
          work_in_holidays: !@user_config.work_in_holidays
        }

        put_with_token api_user_settings_url, @data

        expect(response).to have_http_status(:ok)

        data = JSON.parse(response.body)
        expect(data).to include "day", "day_type", "income_cents", "income_option", "work_in_holidays"

        expect(data["income_cents"]).to eq 0
      end
    end

    context "should response with error messages" do
      before(:each) do
        @data = {
          day: @day_list.reject { |i| i == @user_config.day }.sample,
          day_type: @user_config.all_days? ? :work_day : :all_days,
          income: @user_config.income.to_f + 1,
          income_option: @user_config.next_work_day? ? :previous_day : :next_work_day,
          work_in_holidays: !@user_config.work_in_holidays
        }
      end

      context 'when has invalid day' do
        it 'with day is missing' do
          put_with_token api_user_settings_url, @data.except(:day)

          expect(response.content_type).to eq("application/json; charset=utf-8")
          expect(response).to have_http_status(:unprocessable_entity)

          data = JSON.parse(response.body)
          expect(data).to include "day"
        end
        it 'with day less than 1' do
          put_with_token api_user_settings_url, { day: 0 }

          expect(response.content_type).to eq("application/json; charset=utf-8")
          expect(response).to have_http_status(:unprocessable_entity)

          data = JSON.parse(response.body)
          expect(data).to include "day"
        end
        it 'with day greater than 31 and all_days day type' do
          put_with_token api_user_settings_url, { day: 32, day_type: :all_days }

          expect(response.content_type).to eq("application/json; charset=utf-8")
          expect(response).to have_http_status(:unprocessable_entity)

          data = JSON.parse(response.body)
          expect(data).to include "day"
        end
        it 'with day greater than 20 and work_days day type' do
          put_with_token api_user_settings_url, { day: 21, day_type: :work_day }

          expect(response.content_type).to eq("application/json; charset=utf-8")
          expect(response).to have_http_status(:unprocessable_entity)

          data = JSON.parse(response.body)
          expect(data).to include "day"
        end
      end
      context 'when has invalid day_type' do
        it 'with day_type missing' do
          put_with_token api_user_settings_url, @data.except(:day_type)

          expect(response).to have_http_status(:unprocessable_entity)

          data = JSON.parse(response.body)
          expect(data).to include "day_type"
        end
        it 'with invalid day_type' do
          put_with_token api_user_settings_url, { day_type: :wrong.to_s }

          expect(response.content_type).to eq("application/json; charset=utf-8")
          expect(response).to have_http_status(:unprocessable_entity)

          data = JSON.parse(response.body)
          expect(data).to include "day_type"
        end
      end

      context 'when has invalid income' do
        it 'with invalid income' do
          put_with_token api_user_settings_url, { income: :wrong.to_s }

          expect(response).to have_http_status(:unprocessable_entity)

          data = JSON.parse(response.body)
          expect(data).to include "income"
        end
      end

      context 'when has invalid income_option' do
        it 'with income_option missing' do
          put_with_token api_user_settings_url, @data.except(:income_option)

          expect(response).to have_http_status(:unprocessable_entity)

          data = JSON.parse(response.body)
          expect(data).to include "income_option"
        end
        it 'with invalid income_option' do
          put_with_token api_user_settings_url, { income_option: :wrong.to_s }

          expect(response.content_type).to eq("application/json; charset=utf-8")
          expect(response).to have_http_status(:unprocessable_entity)

          data = JSON.parse(response.body)
          expect(data).to include "income_option"
        end
      end

      context 'when has invalid work_in_holidays' do
        it 'with work_in_holidays missing' do
          put_with_token api_user_settings_url, @data.except(:work_in_holidays)

          expect(response).to have_http_status(:unprocessable_entity)

          data = JSON.parse(response.body)
          expect(data).to include "work_in_holidays"
        end
      end
    end
  end
end
