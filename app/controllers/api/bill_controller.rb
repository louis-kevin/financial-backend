# frozen_string_literal: true

module Api
  class BillController < Api::ApplicationController
    before_action :load_bill, except: %i[index create]
    before_action :load_query, only: %i[index]

    def index
      @bills = current_user.bills
                           .order(:repetition_type, :name)
                           .where(@where)
                           .page(@page)
                           .per(@limit)

      render_pagination(@bills) { |bill| bill_as_json bill }
    end

    def show
      render_json bill_as_json(@bill)
    end

    def create
      account = current_user.accounts.find(bill_params[:account_id])

      @bill = account.bills.create(bill_params)

      return invalid_messages(@bill.errors) unless @bill.valid?

      render_json bill_as_json(@bill), :created
    end

    def update
      @bill.update(bill_params)

      return invalid_messages(@bill.errors) unless @bill.valid?

      render_json bill_as_json(@bill)
    end

    def destroy
      @bill.destroy

      return invalid_messages(@bill.errors) unless @bill.destroyed?

      render_json bill_as_json(@bill)
    end

    private

    def load_bill
      @bill = current_user.bills.find_by id: params[:id]

      render_json({}, :not_found) unless @bill
    end

    def load_query
      @page = params[:page] || 1
      @limit = params[:limit] || 25
      @where = {}

      @where[:account_id] = params[:account_id] if params[:account_id].present?
    end

    def bill_as_json(bill)
      bill.as_json(only: %i[id name amount_cents payed payment_day repetition_type created_at account_id
                            updated_at])
    end

    def bill_params
      params.permit :name, :payed, :amount_cents, :payment_day, :repetition_type, :account_id
    end
  end
end
