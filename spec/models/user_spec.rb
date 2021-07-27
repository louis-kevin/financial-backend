# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  before(:each) do
    @user = create(:user)
  end
  describe '#generate_recovery_token!' do
    it 'should generate a token to reset password' do
      expect(@user.reset_password_token).to be_nil
      @user.generate_recovery_token!
      expect(@user.reset_password_token).to be_present
      expect(@user.reset_password_sent_at).to be_nil
    end
  end

  describe '#generate_jwt_token' do
    it 'should generate a token with payload' do
      token = @user.generate_jwt_token
      expect(token).to be_present

      data = JsonWebToken.decode(token)

      expect(data).to include :id

      id = data[:id]
      expect(id).to eq @user.id
    end
  end

  describe '#find_by_jwt_token' do
    context 'should find a user by token' do
      it 'with Bearer' do
        token = @user.generate_jwt_token
        user = User.find_by_jwt_token "Bearer #{token}"
        expect(user).to eq @user
      end
    end
    context 'should not find user by token' do
      it 'when there ir no Bearer' do
          token = @user.generate_jwt_token
          user = User.find_by_jwt_token token
          expect(user).to be_nil
      end
    end
  end
end
