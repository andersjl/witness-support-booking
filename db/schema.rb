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

ActiveRecord::Schema.define(:version => 20130226092236) do

  create_table "bookings", :force => true do |t|
    t.integer  "user_id",      :null => false
    t.integer  "court_day_id", :null => false
    t.integer  "session",      :null => false
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "bookings", ["court_day_id", "user_id", "session"], :name => "index_bookings_on_court_day_id_and_user_id_and_session", :unique => true
  add_index "bookings", ["court_day_id"], :name => "index_bookings_on_court_day_id"
  add_index "bookings", ["user_id"], :name => "index_bookings_on_user_id"

  create_table "court_days", :force => true do |t|
    t.date     "date",       :null => false
    t.integer  "morning",    :null => false
    t.integer  "afternoon",  :null => false
    t.text     "notes"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.integer  "court_id",   :null => false
  end

  add_index "court_days", ["court_id", "date"], :name => "index_court_days_on_court_id_and_date", :unique => true
  add_index "court_days", ["date"], :name => "index_court_days_on_date"

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
