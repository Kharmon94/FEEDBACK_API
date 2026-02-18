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

ActiveRecord::Schema[8.0].define(version: 2026_02_19_000004) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admin_settings", force: :cascade do |t|
    t.string "site_name", default: "Feedback Page", null: false
    t.string "support_email", default: "support@feedbackpage.com", null: false
    t.integer "max_locations_per_user", default: 100, null: false
    t.boolean "enable_user_registration", default: true, null: false
    t.boolean "enable_email_verification", default: false, null: false
    t.boolean "enable_social_login", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "notify_on_new_feedback", default: true, null: false
    t.boolean "notify_on_new_suggestion", default: true, null: false
  end

  create_table "feedback_submissions", force: :cascade do |t|
    t.integer "location_id", null: false
    t.integer "rating", null: false
    t.text "comment"
    t.string "customer_name"
    t.string "customer_email"
    t.string "phone_number"
    t.boolean "contact_me", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["location_id"], name: "index_feedback_submissions_on_location_id"
  end

  create_table "locations", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "name", null: false
    t.string "slug"
    t.json "review_platforms", default: {}
    t.string "logo_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_locations_on_slug", unique: true
    t.index ["user_id"], name: "index_locations_on_user_id"
  end

  create_table "plans", force: :cascade do |t|
    t.string "slug", null: false
    t.string "name", null: false
    t.integer "monthly_price_cents"
    t.integer "yearly_price_cents"
    t.integer "location_limit"
    t.json "features", default: [], null: false
    t.string "cta"
    t.boolean "highlighted", default: false, null: false
    t.integer "display_order", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_plans_on_active"
    t.index ["display_order"], name: "index_plans_on_display_order"
    t.index ["slug"], name: "index_plans_on_slug", unique: true
  end

  create_table "suggestions", force: :cascade do |t|
    t.integer "location_id"
    t.text "content", null: false
    t.string "submitter_email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["location_id"], name: "index_suggestions_on_location_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "encrypted_password", null: false
    t.string "name"
    t.string "business_name"
    t.string "plan", default: "free"
    t.boolean "admin", default: false
    t.boolean "suspended", default: false
    t.string "provider"
    t.string "uid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "feedback_submissions", "locations"
  add_foreign_key "locations", "users"
  add_foreign_key "suggestions", "locations"
end
