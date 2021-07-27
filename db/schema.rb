# frozen_string_literal: true

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20_200_706_015_716) do
  # These are extensions that must be enabled in order to support this database
  enable_extension 'plpgsql'

  create_table 'accounts', force: :cascade do |t|
    t.bigint 'user_id'
    t.string 'name'
    t.string 'color'
    t.integer 'amount_cents', default: 0, null: false
    t.string 'amount_currency', default: 'USD', null: false
    t.datetime 'created_at', precision: 6, null: false
    t.datetime 'updated_at', precision: 6, null: false
    t.index ['user_id'], name: 'index_accounts_on_user_id'
  end

  create_table 'bills', force: :cascade do |t|
    t.bigint 'account_id', null: false
    t.integer 'amount_cents', default: 0, null: false
    t.string 'amount_currency', default: 'BRL', null: false
    t.string 'name'
    t.boolean 'payed'
    t.integer 'payment_day'
    t.integer 'repetition_type'
    t.datetime 'created_at', precision: 6, null: false
    t.datetime 'updated_at', precision: 6, null: false
    t.index ['account_id'], name: 'index_bills_on_account_id'
  end

  create_table 'user_configs', force: :cascade do |t|
    t.bigint 'user_id', null: false
    t.integer 'day_type'
    t.integer 'day'
    t.integer 'income_option'
    t.integer 'income_cents', default: 0, null: false
    t.string 'income_currency', default: 'BRL', null: false
    t.boolean 'work_in_holidays'
    t.datetime 'created_at', precision: 6, null: false
    t.datetime 'updated_at', precision: 6, null: false
    t.index ['user_id'], name: 'index_user_configs_on_user_id'
  end

  create_table 'users', force: :cascade do |t|
    t.string 'email', default: '', null: false
    t.string 'name', default: '', null: false
    t.string 'password_digest', default: '', null: false
    t.string 'reset_password_token'
    t.datetime 'reset_password_sent_at'
    t.datetime 'created_at', precision: 6, null: false
    t.datetime 'updated_at', precision: 6, null: false
    t.index ['email'], name: 'index_users_on_email', unique: true
    t.index ['reset_password_token'], name: 'index_users_on_reset_password_token', unique: true
  end

  add_foreign_key 'bills', 'accounts'
  add_foreign_key 'user_configs', 'users'
end
