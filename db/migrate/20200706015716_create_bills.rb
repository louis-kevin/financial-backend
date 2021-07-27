# frozen_string_literal: true

class CreateBills < ActiveRecord::Migration[6.0]
  def change
    create_table :bills do |t|
      t.references :account, null: false, foreign_key: true
      t.monetize :amount
      t.string :name
      t.boolean :payed
      t.integer :payment_day
      t.integer :repetition_type

      t.timestamps
    end
  end
end
