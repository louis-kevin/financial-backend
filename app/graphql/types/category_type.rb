module Types
  class CategoryType < Types::BaseObject
    field :id, ID, null: false
    field :name, String, null: true
    field :account_id, Integer, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    field :bills, [Types::BillType], null: true
    field :account, [Types::AccountType], null: true
  end
end
