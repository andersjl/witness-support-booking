# encoding: UTF-8
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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130407080044) do

  create_table "bookings", :force => true do |t|
    t.integer  "user_id",          :null => false
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
    t.integer  "court_session_id", :null => false
  end

  add_index "bookings", ["court_session_id", "user_id"], :name => "index_bookings_on_court_session_id_and_user_id", :unique => true
  add_index "bookings", ["user_id"], :name => "index_bookings_on_user_id"

  create_table "court_day_notes", :force => true do |t|
    t.integer  "court_id",   :null => false
    t.date     "date",       :null => false
    t.text     "text",       :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "court_day_notes", ["court_id"], :name => "index_court_day_notes_on_court_id"
  add_index "court_day_notes", ["date", "court_id"], :name => "index_court_day_notes_on_date_and_court_id", :unique => true

  create_table "court_sessions", :force => true do |t|
    t.integer  "court_id",   :null => false
    t.date     "date",       :null => false
    t.integer  "start",      :null => false
    t.integer  "need",       :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "court_sessions", ["court_id"], :name => "index_court_sessions_on_court_id"
  add_index "court_sessions", ["date", "court_id", "start"], :name => "index_court_sessions_on_date_and_court_id_and_start", :unique => true

  create_table "courts", :force => true do |t|
    t.string   "name",                        :null => false
    t.string   "link",       :default => "#"
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
  end

  add_index "courts", ["name"], :name => "index_courts_on_name", :unique => true

  create_table "users", :force => true do |t|
    t.string   "name",                                    :null => false
    t.string   "email",                                   :null => false
    t.string   "password_digest"
    t.string   "remember_token"
    t.datetime "created_at",                              :null => false
    t.datetime "updated_at",                              :null => false
    t.string   "role",            :default => "disabled"
    t.integer  "court_id",                                :null => false
  end

  add_index "users", ["court_id", "email"], :name => "index_users_on_court_id_and_email", :unique => true
  add_index "users", ["email"], :name => "index_users_on_email"
  add_index "users", ["remember_token"], :name => "index_users_on_remember_token"

end
