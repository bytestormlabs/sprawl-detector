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

ActiveRecord::Schema.define(version: 2022_12_17_221018) do

  create_table "feature_configurations", force: :cascade do |t|
    t.string "tenant_id"
    t.string "key"
    t.string "value"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "findings", force: :cascade do |t|
    t.string "category"
    t.string "account_id"
    t.string "resource_id"
    t.string "issue_type"
    t.string "region"
    t.string "message"
    t.json "metadata"
    t.integer "status_id"
    t.integer "resolution_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "scan_id"
    t.index ["resolution_id"], name: "index_findings_on_resolution_id"
    t.index ["scan_id"], name: "index_findings_on_scan_id"
    t.index ["status_id"], name: "index_findings_on_status_id"
  end

  create_table "findings_tags", id: false, force: :cascade do |t|
    t.integer "finding_id", null: false
    t.integer "tag_id", null: false
  end

  create_table "resolutions", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "resource_filters", force: :cascade do |t|
    t.string "name"
    t.string "value"
    t.string "filter_type", default: "attribute"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "scheduled_operation_id"
    t.index ["scheduled_operation_id"], name: "index_resource_filters_on_scheduled_operation_id"
  end

  create_table "scans", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "scheduled_operations", force: :cascade do |t|
    t.string "operation_type"
  end

  create_table "statuses", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "tags", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  add_foreign_key "findings", "resolutions"
  add_foreign_key "findings", "statuses"
  add_foreign_key "resource_filters", "scheduled_operations"
end
