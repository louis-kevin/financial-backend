class Api::AccountController < Api::ApplicationController
  before_action :load_account, except: [:index, :create, :update_amounts]

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
    accounts = update_amounts_params[:accounts]

    @accounts = current_user.accounts.where(id: accounts.map { |account| account[:id] })

    success = @accounts.empty?

    Account.transaction do
      @accounts.each do |account|
        account_updated = accounts.detect { |account_updated| account_updated[:id].to_i == account.id }

        success = account.update amount_cents: account_updated[:amount_cents]


        raise ActiveRecord::Rollback unless success
      end
    end

    return render_error('Invalid Accounts') unless success

    render_json @accounts.map { |account| account_as_json account }
  end

  private

  def load_account
    @account = current_user.accounts.find_by id: params[:id]

    render_json({}, :not_found) unless @account
  end

  def account_as_json(account)
    data = account.as_json(only: [:id, :name, :color, :amount_cents, :created_at, :user_id, :updated_at])
    data[:total_amount_cents] = account.total_amount_cents
    data
  end

  def account_params
    data = params.permit :name, :color, :amount_cents
    data.merge! user: current_user
  end

  def update_amounts_params
    params.permit(accounts: [:id, :amount_cents])
  end
end
