# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2023_01_07_220259) do
  create_table "accounts", force: :cascade do |t|
    t.string "account_id"
    t.string "external_id"
    t.integer "tenant_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id"], name: "index_accounts_on_tenant_id"
  end

  create_table "aws_cost_line_items", force: :cascade do |t|
    t.date "date"
    t.string "service"
    t.string "region"
    t.decimal "cost"
    t.integer "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_aws_cost_line_items_on_account_id"
  end

  create_table "findings", force: :cascade do |t|
    t.string "category"
    t.string "issue_type"
    t.string "status"
    t.decimal "estimated_cost", precision: 64, scale: 12
    t.json "params"
    t.integer "resource_id"
    t.integer "account_id"
    t.integer "resolution_id"
    t.integer "scan_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_findings_on_account_id"
    t.index ["resolution_id"], name: "index_findings_on_resolution_id"
    t.index ["resource_id"], name: "index_findings_on_resource_id"
    t.index ["scan_id"], name: "index_findings_on_scan_id"
  end

  create_table "resolutions", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "resources", force: :cascade do |t|
    t.string "resource_id"
    t.string "resource_type"
    t.string "region"
    t.json "metadata"
    t.integer "account_id"
    t.integer "scan_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_resources_on_account_id"
    t.index ["scan_id"], name: "index_resources_on_scan_id"
  end

  create_table "scans", force: :cascade do |t|
    t.integer "account_id"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_scans_on_account_id"
  end

  create_table "tenants", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.string "authentication_token", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tenant_id"
    t.index ["authentication_token"], name: "index_users_on_authentication_token", unique: true
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["tenant_id"], name: "index_users_on_tenant_id"
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "accounts", "tenants"
  add_foreign_key "aws_cost_line_items", "accounts"
  add_foreign_key "findings", "accounts"
  add_foreign_key "findings", "resolutions"
  add_foreign_key "findings", "resources"
  add_foreign_key "findings", "scans"
  add_foreign_key "resources", "accounts"
  add_foreign_key "resources", "scans"
  add_foreign_key "scans", "accounts"
end
