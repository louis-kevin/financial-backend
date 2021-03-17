require 'rails_helper'

RSpec.describe "Api::Bills", type: :request do
  describe 'GET #index' do
    before(:each) do
      @user = create(:user)
      @accounts = create_list(:account, 2, user: @user)
      @params = { total: 50, page: 1, limit: 10 }
    end

    context 'with empty bills' do
      it "should response with a empty bill page list and pagination" do
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

    context 'with bills created' do
      before(:each) do
        @bills_from_first_account = create_list(:bill, @params[:total], account: @accounts.first)
        @bills_from_second_account = create_list(:bill, @params[:total], account: @accounts.second)
      end

      context 'should response bills list ordered by repetition_type and name with pagination' do
        context 'from the first page' do
          it 'filtered by first account' do
            @params[:account_id] = @accounts.first.id
            data = index_request

            items = data["data"]

            expect(items.count).to eq @params[:limit]
            expect(data["page"]).to eq @params[:page]
            expect(data["next_page"]).to eq @params[:page] + 1
            expect(data["prev_page"]).to be_nil
            expect(data["total"]).to eq @params[:total]
            expect(data["needs_load_more"]).to be_truthy

            validate_bill_names items, @bills_from_first_account
          end

          it 'filtered by second account' do
            @params[:account_id] = @accounts.second.id
            data = index_request

            items = data["data"]

            expect(items.count).to eq @params[:limit]
            expect(data["page"]).to eq @params[:page]
            expect(data["next_page"]).to eq @params[:page] + 1
            expect(data["prev_page"]).to be_nil
            expect(data["total"]).to eq @params[:total]
            expect(data["needs_load_more"]).to be_truthy

            validate_bill_names items, @bills_from_second_account
          end
        end
        context 'from the second page' do
          it 'filtered by first account' do
            @params[:page] = 2
            @params[:account_id] = @accounts.first.id
            data = index_request

            items = data["data"]

            expect(items.count).to eq @params[:limit]
            expect(data["page"]).to eq @params[:page]
            expect(data["next_page"]).to eq @params[:page] + 1
            expect(data["prev_page"]).to eq @params[:page] - 1
            expect(data["total"]).to eq @params[:total]
            expect(data["needs_load_more"]).to be_truthy

            validate_bill_names items, @bills_from_first_account
          end

          it 'filtered by second account' do
            @params[:page] = 2
            @params[:account_id] = @accounts.second.id
            data = index_request

            items = data["data"]

            expect(items.count).to eq @params[:limit]
            expect(data["page"]).to eq @params[:page]
            expect(data["next_page"]).to eq @params[:page] + 1
            expect(data["prev_page"]).to eq @params[:page] - 1
            expect(data["total"]).to eq @params[:total]
            expect(data["needs_load_more"]).to be_truthy

            validate_bill_names items, @bills_from_second_account
          end
        end
        context 'from the last page' do
          it 'filtered by first account' do
            @params[:page] = 5
            @params[:account_id] = @accounts.first.id
            data = index_request

            items = data["data"]

            expect(items.count).to eq @params[:limit]
            expect(data["page"]).to eq @params[:page]
            expect(data["next_page"]).to be_nil
            expect(data["prev_page"]).to eq @params[:page] - 1
            expect(data["total"]).to eq @params[:total]
            expect(data["needs_load_more"]).to be_falsey

            validate_bill_names items, @bills_from_first_account
          end

          it 'filtered by second account' do
            @params[:page] = 5
            @params[:account_id] = @accounts.second.id
            data = index_request

            items = data["data"]

            expect(items.count).to eq @params[:limit]
            expect(data["page"]).to eq @params[:page]
            expect(data["next_page"]).to be_nil
            expect(data["prev_page"]).to eq @params[:page] - 1
            expect(data["total"]).to eq @params[:total]
            expect(data["needs_load_more"]).to be_falsey

            validate_bill_names items, @bills_from_second_account
          end
        end
      end
    end
  end

  describe 'GET #show' do
    before(:each) do
      @user = create(:user)
      @account = create(:account, user: @user)
      @bill = create(:bill, account: @account)
    end

    it 'should return the bill data' do
      data = show_request @bill.id
      validate_bill_format data
      compare_data_and_model data, @bill
    end

    context 'should return error' do
      it 'when id does not exists' do
        show_request 'wrong_id', :not_found
      end

      it 'when id does not belongs to user' do
        @other_bill = create(:bill)
        show_request @other_bill.id, :not_found
      end
    end
  end

  describe 'POST #create' do
    before(:each) do
      @user = create(:user)
      @account = create(:account, user: @user)
      @bill = build(:bill, account: @account, payed: false, repetition_type: :monthly)

      @data = {
        name: @bill.name,
        payed: @bill.payed,
        amount_cents: @bill.amount_cents,
        payment_day: @bill.payment_day,
        repetition_type: @bill.repetition_type,
        account_id: @account.id
      }
    end

    it 'should create and return the bill data' do
      data = create_request @data
      expect(Bill.count).to eq 1
      validate_bill_format(data)
      compare_data_and_model data, @bill
    end

    context 'should create and return the bill data without payment day' do
      it 'when is daily' do
        @data.extract! :payment_day
        @data[:repetition_type] = :daily
        data = create_request @data
        expect(Bill.count).to eq 1
        @bill = Bill.first
        validate_bill_format(data)
        compare_data_and_model data, @bill
      end
      it 'when is once' do
        @data.extract! :payment_day
        @data[:repetition_type] = :once
        data = create_request @data
        expect(Bill.count).to eq 1
        @bill = Bill.first
        validate_bill_format(data)
        compare_data_and_model data, @bill
      end
    end

    it 'should create without payment day when daily even if payment day is in data' do
      @data[:repetition_type] = :daily
      data = create_request @data
      expect(Bill.count).to eq 1
      @bill = Bill.first
      validate_bill_format(data)
      expect(data["payment_day"]).to be_nil
      compare_data_and_model data, @bill
    end

    it 'should create with payment day when once' do
      @data[:repetition_type] = :once
      data = create_request @data
      expect(Bill.count).to eq 1
      @bill = Bill.first
      validate_bill_format(data)
      expect(data["payment_day"]).to be_present
      compare_data_and_model data, @bill
    end

    context 'should return error' do
      context 'when name field is wrong' do
        it 'because is missing' do
          @data.extract! :name
          data = create_request @data, :unprocessable_entity
          expect(Bill.count).to eq 0
          expect(data).to include "name"
        end

        it 'because is empty' do
          @data[:name] = ''
          data = create_request @data, :unprocessable_entity
          expect(Bill.count).to eq 0
          expect(data).to include "name"
        end
      end

      context 'when payment_day field is wrong' do
        it 'because is missing and repetition type is monthly' do
          @data.extract! :payment_day
          @data[:repetition_type] = :monthly
          data = create_request @data, :unprocessable_entity
          expect(Bill.count).to eq 0
          expect(data).to include "payment_day"
        end
        it 'because is empty' do
          @data[:payment_day] = ''
          data = create_request @data, :unprocessable_entity
          expect(Bill.count).to eq 0
          expect(data).to include "payment_day"
        end
        it 'because is payment_day greater than 31' do
          @data[:payment_day] = 32
          data = create_request @data, :unprocessable_entity
          expect(Bill.count).to eq 0
          expect(data).to include "payment_day"
        end
        it 'because is payment_day less than 1' do
          @data[:payment_day] = 0
          data = create_request @data, :unprocessable_entity
          expect(Bill.count).to eq 0
          expect(data).to include "payment_day"
        end
      end

      context 'when amount_cents field is wrong' do
        it 'because is missing' do
          data = create_request @data.except(:amount_cents), :unprocessable_entity
          expect(Bill.count).to eq 0
          expect(data).to include "amount_cents"
        end
        it 'because is not a number' do
          @data[:amount_cents] = ''
          data = create_request @data, :unprocessable_entity
          expect(Bill.count).to eq 0
          expect(data).to include "amount_cents"
        end
        it 'because is equal to 0' do
          @data[:amount_cents] = 0
          data = create_request @data, :unprocessable_entity
          expect(Bill.count).to eq 0
          expect(data).to include "amount_cents"
        end

        it 'because is a double' do
          @data[:amount_cents] = 12.3
          data = create_request @data, :unprocessable_entity
          expect(Bill.count).to eq 0
          expect(data).to include "amount_cents"
        end
      end

      context 'when has invalid repetition_type' do
        it 'with repetition_type missing' do
          data = create_request @data.except(:repetition_type), :unprocessable_entity

          expect(data).to include "repetition_type"
        end
        it 'with invalid repetition_type' do
          @data[:repetition_type] = :wrong.to_s
          data = create_request @data, :unprocessable_entity

          expect(data).to include "repetition_type"
        end
      end
    end
  end

  describe 'PUT #update' do
    before(:each) do
      @user = create(:user)
      @account = create(:account, user: @user)
      @bill = create(:bill, account: @account, payed: false, repetition_type: :monthly)

      same_data = {
        account: @account,
        created_at: @bill.created_at,
        id: @bill.id,
        updated_at: @bill.updated_at - 1.second,
        repetition_type: :monthly
      }

      @new_data = build(:bill, same_data)

      @data = {
        id: @bill.id,
        name: @new_data.name,
        payed: @new_data.payed,
        amount_cents: @new_data.amount_cents,
        payment_day: @new_data.payment_day,
        repetition_type: @new_data.repetition_type
      }
    end

    it 'should update and return the new bill data' do
      expect(Bill.count).to eq 1
      data = update_request @data
      validate_bill_format(data)
      compare_data_and_model data, @new_data, true
    end

    it 'should empty the payment day when updating to daily' do
      @new_data.payment_day = nil
      @new_data.repetition_type = :daily
      @data.extract! :payment_day
      @data[:repetition_type] = :daily
      expect(@bill.payment_day).to be_present
      expect(Bill.count).to eq 1
      data = update_request @data
      validate_bill_format(data)
      compare_data_and_model data, @new_data, true
      expect(@bill.reload.payment_day).to be_nil
    end

    it 'should not empty the payment day when updating to once' do
      @new_data.payment_day = @bill.payment_day
      @new_data.repetition_type = :once
      @data.extract! :payment_day
      @data[:repetition_type] = :once
      expect(@bill.payment_day).to be_present
      expect(Bill.count).to eq 1
      data = update_request @data
      validate_bill_format(data)
      compare_data_and_model data, @new_data, true
      expect(@bill.reload.payment_day).to be_present
    end

    it 'should allow empty the payment day when updating to once' do
      @bill.update repetition_type: :daily
      @new_data.payment_day = @bill.payment_day
      @new_data.repetition_type = :once
      @data.extract! :payment_day
      @data[:repetition_type] = :once
      expect(@bill.payment_day).to be_nil
      expect(Bill.count).to eq 1
      data = update_request @data
      validate_bill_format(data)
      compare_data_and_model data, @new_data, true
      expect(@bill.reload.payment_day).to be_nil
    end

    it 'should not update the user_id' do
      expect(Bill.count).to eq 1
      new_account = create(:account, user: @user)
      @data[:account_id] = new_account.id
      old_user_id = @bill.user.id
      data = update_request @data
      validate_bill_format(data)
      compare_data_and_model data, @new_data, true
      @bill.reload
      expect(@bill.user.id).to eq old_user_id
    end

    context 'should return error' do
      before(:each) do
        @old_data = {
          name: @bill.name,
          payed: @bill.payed,
          amount_cents: @bill.amount_cents,
          payment_day: @bill.payment_day,
          repetition_type: @bill.repetition_type
        }
      end

      after(:each) do
        @bill.reload
        expect(@old_data[:name]).to eq @bill.name
        expect(@old_data[:payed]).to eq @bill.payed
        expect(@old_data[:amount_cents]).to eq @bill.amount_cents
        expect(@old_data[:payment_day]).to eq @bill.payment_day
        expect(@old_data[:repetition_type]).to eq @bill.repetition_type
      end

      it 'when id does not exists' do
        update_request({ id: 'wrong_id' }, :not_found)
      end

      it 'when id does not belongs to user' do
        @other_bill = create(:bill)
        update_request({ id: @other_bill.id }, :not_found)
      end

      context 'when name field is wrong' do
        it 'because is empty' do
          @data[:name] = ''
          old_name = @bill.name
          data = update_request @data, :unprocessable_entity
          expect(data).to include "name"
          @bill.reload
          expect(@bill.name).to eq old_name
        end
      end

      context 'when payment_day field is wrong' do
        it 'because is missing and repetition type is monthly' do
          @bill.update repetition_type: :daily
          @old_data[:payment_day] = nil
          @old_data[:repetition_type] = :daily.to_s
          expect(@bill.payment_day).to be_nil
          @data[:repetition_type] = :monthly
          @data.extract! :payment_day
          data = update_request @data, :unprocessable_entity
          expect(data).to include "payment_day"
        end
        it 'because is payment_day greater than 31' do
          @data[:payment_day] = 32
          data = update_request @data, :unprocessable_entity
          expect(data).to include "payment_day"
        end
        it 'because is payment_day less than 1' do
          @data[:payment_day] = 0
          data = update_request @data, :unprocessable_entity
          expect(data).to include "payment_day"
        end
      end

      context 'when amount_cents field is wrong' do
        it 'because is not a number' do
          @data[:amount_cents] = ''
          data = update_request @data, :unprocessable_entity
          expect(data).to include "amount_cents"
        end
        it 'because is equal to 0' do
          @data[:amount_cents] = 0
          data = update_request @data, :unprocessable_entity
          expect(data).to include "amount_cents"
        end
        it 'because is a double' do
          @data[:amount_cents] = 12.3
          data = update_request @data, :unprocessable_entity
          expect(data).to include "amount_cents"
        end
      end

      context 'when has invalid repetition_type' do
        # TODO Check why is valid? is true
        # it 'with invalid repetition_type' do
        #   @data[:repetition_type] = :wrong
        #   data = update_request @data, :unprocessable_entity
        #   expect(data).to include "repetition_type"
        # end
      end
    end
  end

  describe 'DELETE #destroy' do
    before(:each) do
      @user = create(:user)
      @bill = create(:bill, user: @user)
    end

    it 'should delete and return the bill data' do
      expect(Bill.count).to eq 1
      destroy_request @bill.id
      expect(Bill.count).to eq 0
    end

    context 'should return error' do
      it 'when id does not exists' do
        destroy_request('wrong_id', :not_found)
      end

      it 'when id does not belongs to user' do
        @other_bill = create(:bill)
        destroy_request(@other_bill.id, :not_found)
      end
    end
  end

  private

  def index_request
    get_with_token api_bills_url, @params.except(:total)

    expect(response).to have_http_status(:ok)

    data = JSON.parse(response.body)

    expect(data).to include "data", "total", "page", "next_page", "prev_page", "needs_load_more"

    data["data"].each { |bill| validate_bill_format bill }

    data
  end

  def show_request(id, status = :ok)
    get_with_token api_bill_url(id)

    expect(response).to have_http_status(status)
    JSON.parse(response.body)
  end

  def create_request(params, status = :created)
    expect(Bill.count).to eq 0
    post_with_token api_bill_index_url, params

    expect(response).to have_http_status(status)
    JSON.parse(response.body)
  end

  def update_request(params, status = :ok)
    put_with_token api_bill_url(params[:id]), params

    expect(response).to have_http_status(status)
    JSON.parse(response.body)
  end

  def destroy_request(id, status = :ok)
    delete_with_token api_bill_url(id)

    expect(response).to have_http_status(status)
  end

  def validate_bill_names(items, list)
    response_names = items.pluck("name")

    bill_sorted = list.sort do |a, b|
      result = b.repetition_type <=> a.repetition_type

      return result unless result == 0

      b.name <=> a.name
    end

    start_range = @params[:page] == 1 ? 0 : (@params[:page] - 1) * @params[:limit]
    end_range = @params[:page] == 1 ? @params[:limit] - 1 : (@params[:page] * @params[:limit]) - 1

    bills_names = bill_sorted.pluck(:name)[start_range..end_range]

    expect(bills_names).to eq response_names
  end

  def validate_bill_format(data)
    expect(data).to include "id",
                            "name",
                            "repetition_type",
                            "amount_cents",
                            "payed",
                            "payment_day",
                            "created_at",
                            "updated_at",
                            "account_id"
    data
  end

  def compare_data_and_model(data, bill, updated = false)
    expect(data["name"]).to eq bill.name
    expect(data["repetition_type"]).to eq bill.repetition_type
    expect(data["amount_cents"]).to eq bill.amount_cents
    expect(data["payed"]).to eq bill.payed
    expect(data["payment_day"]).to eq bill.payment_day

    if bill.id?
      expect(data["id"]).to eq bill.id if bill.id?
      expect(DateTime.parse(data["created_at"]).to_i).to eq bill.created_at.to_i

      if updated
        expect(DateTime.parse(data["updated_at"]).to_i).to be > bill.updated_at.to_i
      else
        expect(DateTime.parse(data["updated_at"]).to_i).to eq bill.updated_at.to_i
      end
    end
  end
end
