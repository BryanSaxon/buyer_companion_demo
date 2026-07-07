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

ActiveRecord::Schema[8.1].define(version: 2026_07_02_034720) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "chat_messages", force: :cascade do |t|
    t.text "component_html"
    t.string "component_type"
    t.text "content"
    t.datetime "created_at", null: false
    t.bigint "lead_id", null: false
    t.string "message_type", default: "text", null: false
    t.string "role"
    t.datetime "updated_at", null: false
    t.index ["lead_id"], name: "index_chat_messages_on_lead_id"
  end

  create_table "design_renders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "design_session_id", null: false
    t.text "prompt"
    t.string "room_key", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["design_session_id", "room_key"], name: "index_design_renders_on_design_session_id_and_room_key", unique: true
    t.index ["design_session_id"], name: "index_design_renders_on_design_session_id"
  end

  create_table "design_selections", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "design_session_id", null: false
    t.string "option_key", null: false
    t.string "option_label", null: false
    t.boolean "pending", default: false, null: false
    t.string "room_key", null: false
    t.string "selection_type", null: false
    t.datetime "updated_at", null: false
    t.index ["design_session_id", "room_key", "selection_type"], name: "idx_design_selections_unique", unique: true
    t.index ["design_session_id"], name: "index_design_selections_on_design_session_id"
  end

  create_table "design_sessions", force: :cascade do |t|
    t.string "aasm_state", default: "welcome", null: false
    t.datetime "created_at", null: false
    t.string "current_room"
    t.integer "current_selection_index", default: 0, null: false
    t.text "custom_family_json"
    t.text "design_styles"
    t.bigint "lead_id", null: false
    t.boolean "planning_complete", default: false, null: false
    t.boolean "style_selected", default: false, null: false
    t.boolean "summary_approved", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["lead_id"], name: "index_design_sessions_on_lead_id", unique: true
  end

  create_table "draft_emails", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.bigint "design_session_id", null: false
    t.text "original_question", null: false
    t.string "subject", null: false
    t.datetime "updated_at", null: false
    t.index ["design_session_id"], name: "index_draft_emails_on_design_session_id"
  end

  create_table "leads", force: :cascade do |t|
    t.string "company"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "first_name"
    t.string "last_name"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_leads_on_email"
  end

  create_table "page_views", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "event"
    t.string "ip_address"
    t.integer "lead_id"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.index ["created_at"], name: "index_page_views_on_created_at"
    t.index ["lead_id"], name: "index_page_views_on_lead_id"
  end

  create_table "room_plans", force: :cascade do |t|
    t.boolean "complete", default: false, null: false
    t.datetime "created_at", null: false
    t.bigint "design_session_id", null: false
    t.text "occupants"
    t.string "purpose"
    t.string "purpose_label"
    t.string "room_key", null: false
    t.boolean "skipped", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["design_session_id", "room_key"], name: "index_room_plans_on_design_session_id_and_room_key", unique: true
    t.index ["design_session_id"], name: "index_room_plans_on_design_session_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "chat_messages", "leads"
  add_foreign_key "design_renders", "design_sessions"
  add_foreign_key "design_selections", "design_sessions"
  add_foreign_key "design_sessions", "leads"
  add_foreign_key "draft_emails", "design_sessions"
  add_foreign_key "room_plans", "design_sessions"
end
