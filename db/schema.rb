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

ActiveRecord::Schema[7.2].define(version: 2025_07_09_210719) do
  create_table "api_keys", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name"
    t.text "encrypted_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_api_keys_on_user_id"
  end

  create_table "scans", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "plugin_name"
    t.string "file_path"
    t.string "status"
    t.text "scan_results"
    t.text "ai_analysis"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_scans_on_status"
    t.index ["user_id"], name: "index_scans_on_user_id"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "admin", default: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "vulnerabilities", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "scan_id", null: false
    t.string "file_path"
    t.integer "line_number"
    t.string "vulnerability_type"
    t.string "severity"
    t.text "description"
    t.text "code_snippet"
    t.text "ai_explanation"
    t.text "fix_suggestion"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scan_id"], name: "index_vulnerabilities_on_scan_id"
    t.index ["severity"], name: "index_vulnerabilities_on_severity"
  end

  add_foreign_key "api_keys", "users"
  add_foreign_key "scans", "users"
  add_foreign_key "vulnerabilities", "scans"
end
