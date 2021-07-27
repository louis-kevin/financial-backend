# frozen_string_literal: true

class CreateAccounts < ActiveRecord::Migration[6.0]
  def change
    create_table :account do |t|
      t.references :user
      t.string :name
      t.string :color
      t.monetize :amount

      t.timestamps
    end
  end
end
