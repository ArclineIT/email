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

ActiveRecord::Schema[8.1].define(version: 2026_10_10_110001) do
  create_table "aliases", force: :cascade do |t|
    t.integer "domain_id", null: false
    t.string "local_part", null: false
    t.string "address", null: false
    t.text "destinations", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address"], name: "index_aliases_on_address", unique: true
    t.index ["domain_id"], name: "index_aliases_on_domain_id"
  end

  create_table "domains", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "active", default: true, null: false
    t.string "catch_all", default: "", null: false
    t.string "dkim_selector", default: "arcline", null: false
    t.text "dkim_private_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_domains_on_name", unique: true
  end

  create_table "mailboxes", force: :cascade do |t|
    t.integer "domain_id", null: false
    t.string "local_part", null: false
    t.string "address", null: false
    t.string "display_name", default: "", null: false
    t.string "password_digest", null: false
    t.integer "quota_mb", default: 1024, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address"], name: "index_mailboxes_on_address", unique: true
    t.index ["domain_id"], name: "index_mailboxes_on_domain_id"
  end

  add_foreign_key "aliases", "domains", on_delete: :cascade
  add_foreign_key "mailboxes", "domains", on_delete: :cascade
end
