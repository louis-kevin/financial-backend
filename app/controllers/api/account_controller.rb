# frozen_string_literal: true

module Api
  class AccountController < Api::ApplicationController
    before_action :load_account, except: %i[index create update_amounts]
    before_action :load_accounts, only: %i[update_amounts]

    def index
      page = params[:page] || 1
      limit = params[:limit] || 25
      @accounts = current_user.accounts.order(:name).page(page).per(limit)

      render_pagination(@accounts) { |account| account_as_json account }
    end

    def show
      render_json account_as_json(@account)
    end

    def create
      @account = Account.create(account_params)

      return invalid_messages(@account.errors) unless @account.valid?

      render_json account_as_json(@account), :created
    end

    def update
      @account.update(account_params)

      return invalid_messages(@account.errors) unless @account.valid?

      render_json account_as_json(@account)
    end

    def destroy
      @account.destroy

      return invalid_messages(@account.errors) unless @account.destroyed?

      render_json account_as_json(@account)
    end

    def update_amounts
      Account.transaction do
        @accounts.each do |account|
          new_account_updated = @accounts_to_update.detect { |account_updated| account_updated[:id].to_i == account.id }

          @success = account.update amount_cents: new_account_updated[:amount_cents]

          raise ActiveRecord::Rollback unless @success
        end
      end

      return render_error('Invalid Accounts') unless @success

      render_json(@accounts.map { |account| account_as_json account })
    end

    private

    def load_account
      @account = current_user.accounts.find_by id: params[:id]

      render_json({}, :not_found) unless @account
    end

    def load_accounts
      @accounts_to_update = update_amounts_params[:accounts]

      @accounts = current_user.accounts.where(id: @accounts_to_update.map { |account| account[:id] })

      @success = @accounts.empty?
    end

    def account_as_json(account)
      data = account.as_json(only: %i[id name color amount_cents created_at user_id updated_at])
      data[:total_amount_cents] = account.total_amount_cents
      data
    end

    def account_params
      data = params.permit :name, :color, :amount_cents
      data.merge! user: current_user
    end

    def update_amounts_params
      params.permit(accounts: %i[id amount_cents])
    end
  end
end
