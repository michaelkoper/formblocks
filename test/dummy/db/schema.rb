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

ActiveRecord::Schema[8.1].define(version: 2026_09_14_210947) do
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

  create_table "formblocks_blocks", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.text "help_text"
    t.string "key"
    t.string "label"
    t.json "options"
    t.integer "page_id", null: false
    t.string "placeholder"
    t.integer "position", default: 0, null: false
    t.boolean "required", default: false, null: false
    t.json "settings"
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.index ["page_id"], name: "index_formblocks_blocks_on_page_id"
  end

  create_table "formblocks_forms", force: :cascade do |t|
    t.string "button_text_color"
    t.datetime "created_at", null: false
    t.string "primary_color"
    t.datetime "published_at"
    t.integer "responses_count", default: 0, null: false
    t.string "slug", null: false
    t.string "tenant"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_formblocks_forms_on_slug", unique: true
    t.index ["tenant"], name: "index_formblocks_forms_on_tenant"
  end

  create_table "formblocks_pages", force: :cascade do |t|
    t.string "button_text"
    t.datetime "created_at", null: false
    t.integer "form_id", null: false
    t.string "kind", default: "step", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["form_id"], name: "index_formblocks_pages_on_form_id"
  end

  create_table "formblocks_responses", force: :cascade do |t|
    t.json "answers"
    t.datetime "created_at", null: false
    t.integer "form_id", null: false
    t.string "locale"
    t.string "page_url"
    t.string "tenant"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.index ["form_id"], name: "index_formblocks_responses_on_form_id"
    t.index ["tenant", "created_at"], name: "index_formblocks_responses_on_tenant_and_created_at"
  end

  create_table "formblocks_settings", force: :cascade do |t|
    t.string "button_text_color"
    t.datetime "created_at", null: false
    t.string "primary_color"
    t.string "tenant"
    t.datetime "updated_at", null: false
    t.index ["tenant"], name: "index_formblocks_settings_on_tenant", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "formblocks_blocks", "formblocks_pages", column: "page_id"
  add_foreign_key "formblocks_pages", "formblocks_forms", column: "form_id"
  add_foreign_key "formblocks_responses", "formblocks_forms", column: "form_id"
end
