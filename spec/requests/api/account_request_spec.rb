require 'rails_helper'

RSpec.describe "Api::AccountController", type: :request do
  describe 'GET #index' do
    before(:each) do
      @user = create(:user)
      @params = { total: 50, page: 1, limit: 10 }
    end

    context 'with empty accounts' do
      it "should response with a empty account page list and pagination" do
        data = index_request

        items = data["data"]

        expect(items.count).to eq 0
        expect(data["page"]).to eq @params[:page]
        expect(data["next_page"]).to be_nil
        expect(data["prev_page"]).to be_nil
        expect(data["total"]).to eq 0
        expect(data["needs_load_more"]).to be_falsey
      end
    end

    context 'with accounts created' do
      before(:each) do
        @accounts = create_list(:account, @params[:total], user: @user)
      end

      it "should response with the first page of accounts list ordered by name and pagination" do
        data = index_request

        items = data["data"]

        expect(items.count).to eq @params[:limit]
        expect(data["page"]).to eq @params[:page]
        expect(data["next_page"]).to eq @params[:page] + 1
        expect(data["prev_page"]).to be_nil
        expect(data["total"]).to eq @params[:total]
        expect(data["needs_load_more"]).to be_truthy

        response_names = items.pluck("name")
        accounts_names = @accounts.pluck(:name).sort[0..9]

        expect(accounts_names).to eq response_names
      end

      it "should response with second page of accounts list ordered by name and pagination" do
        @params[:page] = 2

        data = index_request

        items = data["data"]

        expect(items.count).to eq @params[:limit]
        expect(data["page"]).to eq @params[:page]
        expect(data["next_page"]).to eq @params[:page] + 1
        expect(data["prev_page"]).to eq @params[:page] - 1
        expect(data["total"]).to eq @params[:total]
        expect(data["needs_load_more"]).to be_truthy

        response_names = items.pluck("name")
        accounts_names = @accounts.pluck(:name).sort[10..19]

        expect(accounts_names).to eq response_names
      end

      it "should response with last page of accounts list ordered by name and pagination" do
        @params[:page] = 5

        data = index_request

        items = data["data"]

        expect(items.count).to eq @params[:limit]
        expect(data["page"]).to eq @params[:page]
        expect(data["next_page"]).to be_nil
        expect(data["prev_page"]).to eq @params[:page] - 1
        expect(data["total"]).to eq @params[:total]
        expect(data["needs_load_more"]).to be_falsey

        response_names = items.pluck("name")
        accounts_names = @accounts.pluck(:name).sort[40..49]

        expect(accounts_names).to eq response_names
      end
    end
  end

  describe 'GET #show' do
    before(:each) do
      @user = create(:user)
      @account = create(:account, user: @user)
    end

    it 'should return the account data' do
      data = show_request @account.id
      validate_account_format data
      compare_data_and_model data, @account
    end

    context 'should return error' do
      it 'when id does not exists' do
        show_request 'wrong_id', :not_found
      end

      it 'when id does not belongs to user' do
        @other_account = create(:account)
        show_request @other_account.id, :not_found
      end
    end
  end

  describe 'POST #create' do
    before(:each) do
      @user = create(:user)
      @account = build(:account, user: @user)
      @data = {
        name: @account.name,
        color: @account.color,
        amount: @account.amount.to_f
      }
    end

    it 'should create and return the account data' do
      data = create_request @data
      expect(Account.count).to eq 1
      validate_account_format(data)
      compare_data_and_model data, @account
    end

    it 'should create and return the account data even without amount' do
      @data.extract! :amount
      @account.amount = nil
      data = create_request @data
      expect(Account.count).to eq 1
      validate_account_format(data)
      compare_data_and_model data, @account
    end

    context 'should return error' do
      context 'when name field is wrong' do
        it 'because is missing' do
          @data.extract! :name
          data = create_request @data, :unprocessable_entity
          expect(Account.count).to eq 0
          expect(data).to include "name"
        end

        it 'because is empty' do
          @data[:name] = ''
          data = create_request @data, :unprocessable_entity
          expect(Account.count).to eq 0
          expect(data).to include "name"
        end
      end

      context 'when color field is wrong' do
        it 'because is missing' do
          @data.extract! :color
          data = create_request @data, :unprocessable_entity
          expect(Account.count).to eq 0
          expect(data).to include "color"

        end

        it 'because is empty' do
          @data[:color] = ''
          data = create_request @data, :unprocessable_entity
          expect(Account.count).to eq 0
          expect(data).to include "color"
        end

        it 'because is wrong format' do
          @data[:color] = 'wrong format'
          data = create_request @data, :unprocessable_entity
          expect(Account.count).to eq 0
          expect(data).to include "color"
        end
      end

      context 'when amount field is wrong' do
        it 'because is not a number' do
          @data[:amount] = ''
          data = create_request @data, :unprocessable_entity
          expect(Account.count).to eq 0
          expect(data).to include "amount"
        end
      end
    end
  end

  describe 'PUT #update' do
    before(:each) do
      @user = create(:user)
      @account = create(:account, user: @user)
      same_data = { user: @user, created_at: @account.created_at, id: @account.id, updated_at: @account.updated_at - 1.second }
      @new_data = build(:account, same_data)
      @data = {
        id: @account.id,
        name: @new_data.name,
        color: @new_data.color,
        amount: @new_data.amount.to_f
      }
    end

    it 'should update and return the new account data' do
      expect(Account.count).to eq 1
      data = update_request @data
      validate_account_format(data)
      compare_data_and_model data, @new_data, true
    end

    it 'should not update the user_id' do
      expect(Account.count).to eq 1
      new_user = create(:user)
      @data[:user_id] = new_user.id
      data = update_request @data
      validate_account_format(data)
      compare_data_and_model data, @new_data, true
    end

    context 'should return error' do
      it 'when id does not exists' do
        update_request({ id: 'wrong_id' }, :not_found)
      end

      it 'when id does not belongs to user' do
        @other_account = create(:account)
        update_request({ id: @other_account.id }, :not_found)
      end
      context 'when name field is wrong' do
        it 'because is missing' do
          @data[:name] = ''
          data = update_request @data, :unprocessable_entity
          expect(data).to include "name"
        end
      end
      context 'when color field is wrong' do
        it 'because is wrong format' do
          @data[:color] = 'wrong format'
          data = update_request @data, :unprocessable_entity
          expect(data).to include "color"
        end

        it 'because is missing' do
          @data[:color] = ''
          data = update_request @data, :unprocessable_entity
          expect(data).to include "color"
        end
      end

      context 'when amount field is wrong' do
        it 'because is not a number' do
          @data[:amount] = ''
          data = update_request @data, :unprocessable_entity
          expect(data).to include "amount"
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    before(:each) do
      @user = create(:user)
      @account = create(:account, user: @user)
    end

    it 'should delete and return the account data' do
      expect(Account.count).to eq 1
      destroy_request @account.id
      expect(Account.count).to eq 0
    end

    context 'should return error' do
      it 'when id does not exists' do
        destroy_request('wrong_id', :not_found)
      end

      it 'when id does not belongs to user' do
        @other_account = create(:account)
        destroy_request(@other_account.id, :not_found)
      end
    end
  end

  private

  def index_request
    get_with_token api_accounts_url, @params.except(:total)

    expect(response).to have_http_status(:ok)

    data = JSON.parse(response.body)

    expect(data).to include "data", "total", "page", "next_page", "prev_page", "needs_load_more"

    data["data"].each { |account| validate_account_format account }

    data
  end

  def show_request(id, status = :ok)
    get_with_token api_account_url, { id: id }

    expect(response).to have_http_status(status)
    JSON.parse(response.body)
  end

  def create_request(params, status = :created)
    expect(Account.count).to eq 0
    post_with_token api_account_url, params

    expect(response).to have_http_status(status)
    JSON.parse(response.body)
  end

  def update_request(params, status = :ok)
    put_with_token api_account_url, params

    expect(response).to have_http_status(status)
    JSON.parse(response.body)
  end

  def destroy_request(id, status = :ok)
    delete_with_token api_account_url, { id: id }

    expect(response).to have_http_status(status)
  end

  def validate_account_format(data)
    expect(data).to include "id", "name", "color", "amount_cents", "created_at", "updated_at", "user_id"
    data
  end

  def compare_data_and_model(data, account, updated = false)
    expect(data["name"]).to eq account.name
    expect(data["color"]).to eq account.color
    expect(data["amount_cents"]).to eq account.amount_cents.to_f
    expect(data["user_id"]).to eq account.user_id

    if account.id?
      expect(data["id"]).to eq account.id if account.id?
      expect(DateTime.parse(data["created_at"]).to_i).to eq account.created_at.to_i

      if updated
        expect(DateTime.parse(data["updated_at"]).to_i).to be > account.updated_at.to_i
      else
        expect(DateTime.parse(data["updated_at"]).to_i).to eq account.updated_at.to_i
      end

    end
  end
end
