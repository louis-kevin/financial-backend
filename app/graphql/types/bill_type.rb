module Types
  class BillType < Types::BaseObject
    field :id, ID, null: false
    field :account_id, Integer, null: false
    field :amount_cents, Integer, null: false
    field :amount_currency, String, null: false
    field :name, String, null: true
    field :payed, Boolean, null: true
    field :payment_day, Integer, null: true
    field :repetition_type, Integer, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    field :category_id, Integer, null: true
    field :categories, [Types::CategoryType], null: true
    field :account, [Types::AccountType], null: true
  end
end
