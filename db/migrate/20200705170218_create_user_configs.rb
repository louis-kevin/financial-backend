class CreateUserConfigs < ActiveRecord::Migration[6.0]
  def change
    create_table :user_configs do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :day_type
      t.integer :day
      t.integer :income_option
      t.monetize :income
      t.boolean :work_in_holidays

      t.timestamps
    end
  end
end
