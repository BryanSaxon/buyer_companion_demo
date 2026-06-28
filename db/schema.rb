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

ActiveRecord::Schema[8.1].define(version: 2026_06_28_030137) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "chat_messages", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.bigint "lead_id", null: false
    t.string "role"
    t.datetime "updated_at", null: false
    t.index ["lead_id"], name: "index_chat_messages_on_lead_id"
  end

  create_table "leads", force: :cascade do |t|
    t.boolean "approved_render", default: false, null: false
    t.string "company"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "first_name"
    t.string "last_name"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_leads_on_email"
  end

  add_foreign_key "chat_messages", "leads"
end
