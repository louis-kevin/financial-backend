module Types
  class AccountType < Types::BaseObject
    field :id, ID, null: false
    field :user_id, Integer, null: true
    field :name, String, null: true
    field :color, String, null: true
    field :amount_cents, Integer, null: false
    field :amount_currency, String, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    field :name, String, null: true
    field :color, String, null: true
    field :amount_cents, Integer, null: true
    field :bills, [Types::BillType], null: true
    field :categories, [Types::CategoryType], null: true
  end
end
