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

ActiveRecord::Schema[7.2].define(version: 2026_01_20_045758) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "campaigns", force: :cascade do |t|
    t.string "title", null: false
    t.string "status", default: "pending", null: false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying::text, 'processing'::character varying::text, 'completed'::character varying::text])", name: "campaigns_status_check"
  end

  create_table "recipients", force: :cascade do |t|
    t.bigint "campaign_id", null: false
    t.string "name", null: false
    t.string "email"
    t.string "status", default: "queued", null: false
    t.datetime "sent_at"
    t.string "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "phone_number"
    t.index ["campaign_id", "email"], name: "index_recipients_on_campaign_id_and_email", unique: true
    t.index ["campaign_id", "phone_number"], name: "index_recipients_on_campaign_id_and_phone_number", unique: true
    t.index ["campaign_id", "status"], name: "index_recipients_on_campaign_id_and_status"
    t.check_constraint "email IS NOT NULL OR phone_number IS NOT NULL", name: "recipients_email_or_phone_check"
    t.check_constraint "status::text = ANY (ARRAY['queued'::character varying::text, 'sent'::character varying::text, 'failed'::character varying::text])", name: "recipients_status_check"
  end

  add_foreign_key "recipients", "campaigns"
end
