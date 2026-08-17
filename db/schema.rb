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

ActiveRecord::Schema[8.0].define(version: 2026_08_17_214000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "preferences", force: :cascade do |t|
    t.string "uuid", null: false
    t.integer "platform_account_id", null: false
    t.string "resource_origin", null: false
    t.string "resource_key", null: false
    t.string "surface", null: false
    t.string "preference_type", null: false
    t.string "context_host"
    t.string "context_association"
    t.string "scope", null: false
    t.string "scope_ref", null: false
    t.string "cardinality", default: "singleton", null: false
    t.string "name"
    t.boolean "is_default", default: false, null: false
    t.jsonb "payload", default: {}, null: false
    t.boolean "stale", default: false, null: false
    t.string "created_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["platform_account_id", "resource_key", "surface", "scope", "scope_ref"], name: "index_preferences_lookup"
    t.index ["platform_account_id", "resource_origin", "resource_key", "surface", "preference_type", "context_host", "context_association", "scope", "scope_ref"], name: "index_preferences_singleton_identity", unique: true, where: "((cardinality)::text = 'singleton'::text)"
    t.index ["uuid"], name: "index_preferences_on_uuid", unique: true
  end
end
