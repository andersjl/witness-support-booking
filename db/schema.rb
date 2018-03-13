# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_03_13_051002) do

  create_table "bookings", force: :cascade do |t|
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "court_session_id", null: false
    t.date "booked_at", null: false
    t.index ["court_session_id", "user_id"], name: "index_bookings_on_court_session_id_and_user_id", unique: true
    t.index ["user_id"], name: "index_bookings_on_user_id"
  end

  create_table "cancelled_bookings", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "court_session_id", null: false
    t.datetime "cancelled_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["court_session_id", "user_id"], name: "index_cancelled_bookings_on_court_session_id_and_user_id"
  end

  create_table "court_day_notes", force: :cascade do |t|
    t.integer "court_id", null: false
    t.date "date", null: false
    t.text "text", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["court_id"], name: "index_court_day_notes_on_court_id"
    t.index ["date", "court_id"], name: "index_court_day_notes_on_date_and_court_id", unique: true
  end

  create_table "court_sessions", force: :cascade do |t|
    t.integer "court_id", null: false
    t.date "date", null: false
    t.integer "start", null: false
    t.integer "need", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["court_id"], name: "index_court_sessions_on_court_id"
    t.index ["date", "court_id", "start"], name: "index_court_sessions_on_date_and_court_id_and_start", unique: true
  end

  create_table "courts", force: :cascade do |t|
    t.string "name", null: false
    t.string "link", default: "#"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_courts_on_name", unique: true
  end

  create_table "snapshots", force: :cascade do |t|
    t.text "all_data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest"
    t.string "remember_token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role", default: "disabled"
    t.integer "court_id", null: false
    t.boolean "zombie", default: false
    t.index ["court_id", "email"], name: "index_users_on_court_id_and_email", unique: true
    t.index ["email"], name: "index_users_on_email"
    t.index ["remember_token"], name: "index_users_on_remember_token"
  end

end
