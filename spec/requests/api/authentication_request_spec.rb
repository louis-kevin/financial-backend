# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::AuthenticationController', type: :request do
  describe 'POST #login' do
    before(:each) do
      @password = 12_345_678.to_s

      @user = create(:user, password: @password)
    end
    context 'should response with user data and token' do
      it 'with config nil' do
        post api_login_url, params: { email: @user.email, password: @password }

        expect(response.content_type).to eq('application/json; charset=utf-8')
        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        expect(data).to include 'id', 'name', 'email', 'token'
        expect(data).not_to include 'config'
        expect(data['id']).to eq @user.id
        expect(data['name']).to eq @user.name
        expect(data['email']).to eq @user.email
      end

      it 'with config fulfilled' do
        @user_config = create(:user_config, user: @user)

        post api_login_url, params: { email: @user.email, password: @password }

        expect(response.content_type).to eq('application/json; charset=utf-8')
        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        expect(data).to include 'id', 'name', 'email', 'token', 'config'
        expect(data['id']).to eq @user.id
        expect(data['name']).to eq @user.name
        expect(data['email']).to eq @user.email
        expect(data['config']).not_to be_nil

        config = data['config']
        expect(config['day_type']).to eq @user_config.day_type
        expect(config['income_cents']).to eq @user_config.income_cents
        expect(config['work_in_holidays']).to eq @user_config.work_in_holidays
        expect(config['day']).to eq @user_config.day
        expect(config['income_option']).to eq @user_config.income_option
      end
    end

    context 'should response with error messages' do
      it 'when has wrong email' do
        post api_login_url, params: { email: 'wrong@email.com' }

        expect(response.content_type).to eq('application/json; charset=utf-8')
        expect(response).to have_http_status(:unprocessable_entity)

        data = JSON.parse(response.body)
        expect(data).not_to include 'id', 'name', 'token'
        expect(data).to include 'email'
      end
      it 'when has the right email but wrong password' do
        data = { email: @user.email, password: 'wrong_password' }

        post api_login_url, params: data

        expect(response.content_type).to eq('application/json; charset=utf-8')
        expect(response).to have_http_status(:unprocessable_entity)

        data = JSON.parse(response.body)
        expect(data).not_to include 'id', 'name', 'token', 'email'
        expect(data).to include 'password'
      end
    end
  end
  describe 'POST #register' do
    before(:each) do
      @data = {
        email: 'test@teste.com',
        password: 123_456.to_s,
        name: 'kevin'
      }
    end
    it 'should response with user data and token' do
      post api_register_url, params: @data

      expect(response.content_type).to eq('application/json; charset=utf-8')
      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)
      expect(data).to include 'id', 'name', 'email', 'token'
      expect(data).not_to include 'config'
      expect(data['name']).to eq @data[:name]
      expect(data['email']).to eq @data[:email]
    end

    context 'should response with error messages' do
      context 'when has invalid email' do
        it 'with email with wrong format' do
          @data[:email] = 'asdfasdfasdfa'
          post api_register_url, params: @data

          expect(response.content_type).to eq('application/json; charset=utf-8')
          expect(response).to have_http_status(:unprocessable_entity)

          data = JSON.parse(response.body)
          expect(data).to include 'email'
        end
        it 'because email is empty' do
          @data[:email] = ''
          post api_register_url, params: @data

          expect(response.content_type).to eq('application/json; charset=utf-8')
          expect(response).to have_http_status(:unprocessable_entity)

          data = JSON.parse(response.body)
          expect(data).to include 'email'
        end

        it 'because email is already exists' do
          User.create(@data)
          post api_register_url, params: @data

          expect(response.content_type).to eq('application/json; charset=utf-8')
          expect(response).to have_http_status(:unprocessable_entity)

          data = JSON.parse(response.body)
          expect(data).to include 'email'
        end
      end
      context 'when password is wrong' do
        it 'because is too short' do
          @data[:password] = '12345'
          post api_register_url, params: @data

          expect(response.content_type).to eq('application/json; charset=utf-8')
          expect(response).to have_http_status(:unprocessable_entity)

          data = JSON.parse(response.body)
          expect(data).to include 'password'
        end
        it 'because is empty' do
          @data[:password] = ''
          post api_register_url, params: @data

          expect(response.content_type).to eq('application/json; charset=utf-8')
          expect(response).to have_http_status(:unprocessable_entity)

          data = JSON.parse(response.body)
          expect(data).to include 'password'
        end
      end
      context 'when name is wrong' do
        it 'because is empty' do
          @data[:name] = ''
          post api_register_url, params: @data

          expect(response.content_type).to eq('application/json; charset=utf-8')
          expect(response).to have_http_status(:unprocessable_entity)

          data = JSON.parse(response.body)
          expect(data).to include 'name'
        end
      end
    end
  end
  describe 'POST #reset_password' do
    before(:each) do
      @user = create(:user)
    end
    context 'should respond with success' do
      include ActiveJob::TestHelper
      it 'generate reset_password_token and queue mailer job' do
        expect(enqueued_jobs.size).to eq 0
        perform_enqueued_jobs do
          post api_reset_password_url, params: { email: @user.email }

          @user.reload

          expect(response.content_type).to eq('application/json; charset=utf-8')
          expect(response).to have_http_status(:ok)
          data = JSON.parse(response.body)
          expect(data).to be_empty
          expect(@user.reset_password_token).to be_present

          mail = ActionMailer::Base.deliveries.last
          expect(mail.to[0]).to eq @user.email
        end
      end

      it 'do not generate reset_password_token neither queue mailer job' do
        expect(enqueued_jobs.size).to eq 0

        post api_reset_password_url, params: { email: 'wrong@email.com' }

        @user.reload

        expect(response.content_type).to eq('application/json; charset=utf-8')
        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        expect(data).to be_empty
        expect(@user.reset_password_token).not_to be_present

        expect(enqueued_jobs.size).to eq 0
      end
    end
  end
end
