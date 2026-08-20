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

ActiveRecord::Schema[8.1].define(version: 2026_08_20_111000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "analysis_requests", force: :cascade do |t|
    t.datetime "archived_at"
    t.integer "automatic_retry_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.text "failure_message"
    t.string "lifecycle_state", default: "queued", null: false
    t.boolean "recoverable_failure", default: false, null: false
    t.string "source_url", null: false
    t.datetime "updated_at", null: false
    t.index ["archived_at"], name: "index_analysis_requests_on_archived_at"
    t.index ["created_at"], name: "index_analysis_requests_on_created_at"
    t.check_constraint "lifecycle_state::text = ANY (ARRAY['queued'::character varying, 'processing'::character varying, 'completed'::character varying, 'failed'::character varying, 'cancelled'::character varying]::text[])", name: "analysis_requests_lifecycle_state"
  end

  create_table "briefs", force: :cascade do |t|
    t.bigint "analysis_request_id", null: false
    t.text "content_markdown", null: false
    t.datetime "created_at", null: false
    t.integer "duration_seconds", null: false
    t.jsonb "key_conclusions", null: false
    t.string "output_language", null: false
    t.boolean "publicly_visible", default: false, null: false
    t.date "published_on", null: false
    t.string "source_channel", null: false
    t.string "source_title", null: false
    t.string "source_url", null: false
    t.jsonb "structured_content", null: false
    t.datetime "updated_at", null: false
    t.index ["analysis_request_id"], name: "index_briefs_on_analysis_request_id", unique: true
    t.index ["publicly_visible"], name: "index_briefs_on_publicly_visible"
  end

  add_foreign_key "briefs", "analysis_requests"
end
