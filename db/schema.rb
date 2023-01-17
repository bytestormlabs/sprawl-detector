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

ActiveRecord::Schema[7.0].define(version: 2023_01_17_010326) do
  create_table "accounts", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "account_id"
    t.string "external_id"
    t.string "name"
    t.bigint "tenant_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id"], name: "index_accounts_on_tenant_id"
  end

  create_table "aws_cost_line_items", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.date "date"
    t.string "service"
    t.string "region"
    t.decimal "cost", precision: 10
    t.bigint "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_aws_cost_line_items_on_account_id"
  end

  create_table "filters", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.string "value"
    t.string "filter_type", default: "attribute"
    t.bigint "resource_filter_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["resource_filter_id"], name: "index_filters_on_resource_filter_id"
  end

  create_table "findings", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "category"
    t.string "issue_type"
    t.string "status"
    t.decimal "estimated_cost", precision: 64, scale: 12
    t.json "params"
    t.bigint "resource_id"
    t.bigint "account_id"
    t.bigint "resolution_id"
    t.bigint "scan_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_findings_on_account_id"
    t.index ["resolution_id"], name: "index_findings_on_resolution_id"
    t.index ["resource_id"], name: "index_findings_on_resource_id"
    t.index ["scan_id"], name: "index_findings_on_scan_id"
  end

  create_table "resolutions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "resource_filters", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "region"
    t.string "resource_type"
    t.integer "ordinal"
    t.bigint "scheduled_plan_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scheduled_plan_id"], name: "index_resource_filters_on_scheduled_plan_id"
  end

  create_table "resources", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "resource_id"
    t.string "resource_type"
    t.string "region"
    t.json "metadata"
    t.bigint "account_id"
    t.bigint "scan_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_resources_on_account_id"
    t.index ["scan_id"], name: "index_resources_on_scan_id"
  end

  create_table "scans", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "account_id"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_scans_on_account_id"
  end

  create_table "scheduled_plans", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "account_id"
    t.string "up_schedule"
    t.string "down_schedule"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_scheduled_plans_on_account_id"
  end

  create_table "settings", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "data_type", default: "integer"
    t.text "description"
    t.string "value"
    t.string "key"
    t.bigint "account_id"
    t.bigint "tenant_id"
    t.bigint "finding_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_settings_on_account_id"
    t.index ["finding_id"], name: "index_settings_on_finding_id"
    t.index ["tenant_id"], name: "index_settings_on_tenant_id"
  end

  create_table "tenants", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
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
    t.bigint "tenant_id"
    t.index ["authentication_token"], name: "index_users_on_authentication_token", unique: true
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["tenant_id"], name: "index_users_on_tenant_id"
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "accounts", "tenants"
  add_foreign_key "aws_cost_line_items", "accounts"
  add_foreign_key "filters", "resource_filters"
  add_foreign_key "findings", "accounts"
  add_foreign_key "findings", "resolutions"
  add_foreign_key "findings", "resources"
  add_foreign_key "findings", "scans"
  add_foreign_key "resource_filters", "scheduled_plans"
  add_foreign_key "resources", "accounts"
  add_foreign_key "resources", "scans"
  add_foreign_key "scans", "accounts"
  add_foreign_key "scheduled_plans", "accounts"
  add_foreign_key "settings", "accounts"
  add_foreign_key "settings", "findings"
  add_foreign_key "settings", "tenants"
end
