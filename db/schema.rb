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

ActiveRecord::Schema.define(:version => 20110823170400) do

  create_table "_answers", :id => false, :force => true do |t|
    t.datetime "observe_time"
    t.boolean  "is_reviewed",                                                              :default => false
    t.string   "form_name"
    t.string   "form_type"
    t.string   "question_code"
    t.text     "question_name"
    t.string   "question_type"
    t.string   "observer_name",      :limit => 511
    t.string   "address_landmark"
    t.string   "locality"
    t.string   "state"
    t.string   "country"
    t.decimal  "latitude",                                 :precision => 20, :scale => 15
    t.decimal  "longitude",                                :precision => 20, :scale => 15
    t.binary   "latitude_longitude", :limit => 45
    t.integer  "answer_id",                                                                :default => 0,     :null => false
    t.text     "answer_value"
    t.text     "choice_name",        :limit => 2147483647
    t.string   "choice_value"
    t.string   "option_set"
  end

  create_table "answers", :force => true do |t|
    t.integer  "response_id"
    t.integer  "option_id"
    t.text     "value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "questioning_id"
  end

  create_table "broadcast_addressings", :force => true do |t|
    t.integer  "broadcast_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "broadcasts", :force => true do |t|
    t.string   "subject"
    t.text     "body"
    t.string   "medium"
    t.text     "send_errors"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "choices", :force => true do |t|
    t.integer  "answer_id"
    t.integer  "option_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "choices", ["answer_id"], :name => "index_choices_on_answer_id"

  create_table "form_types", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "forms", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_published", :default => false
    t.integer  "form_type_id"
    t.integer  "downloads"
  end

  create_table "google_geolocations", :force => true do |t|
    t.string   "full_name"
    t.text     "json"
    t.integer  "place_type_id"
    t.decimal  "latitude",       :precision => 20, :scale => 15
    t.decimal  "longitude",      :precision => 20, :scale => 15
    t.string   "formatted_addr"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "languages", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_active",  :default => false
    t.string   "code"
  end

  create_table "option_sets", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "option_settings", :force => true do |t|
    t.integer  "option_set_id"
    t.integer  "option_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "options", :force => true do |t|
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "place_lookups", :force => true do |t|
    t.string   "query"
    t.string   "sugg_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "place_sugg_sets", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "place_suggs", :force => true do |t|
    t.integer  "place_lookup_id"
    t.integer  "place_id"
    t.integer  "google_geolocation_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "place_types", :force => true do |t|
    t.string   "name"
    t.integer  "level"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "places", :force => true do |t|
    t.string   "long_name"
    t.string   "short_name"
    t.string   "full_name"
    t.integer  "place_type_id"
    t.integer  "container_id"
    t.decimal  "latitude",      :precision => 20, :scale => 15
    t.decimal  "longitude",     :precision => 20, :scale => 15
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_incomplete",                                 :default => false
  end

  create_table "question_types", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "odk_name"
    t.string   "odk_tag"
    t.string   "odk_preload"
    t.string   "odk_preload_params"
    t.boolean  "phone_only",         :default => false
    t.string   "long_name"
  end

  create_table "questionings", :force => true do |t|
    t.integer  "question_id"
    t.integer  "form_id"
    t.integer  "rank"
    t.boolean  "required",    :default => false
    t.boolean  "hidden",      :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "questions", :force => true do |t|
    t.string   "code"
    t.integer  "option_set_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "question_type_id"
  end

  create_table "responses", :force => true do |t|
    t.integer  "form_id"
    t.integer  "user_id"
    t.integer  "place_id"
    t.datetime "observed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "reviewed",    :default => false
    t.string   "source"
  end

  create_table "roles", :force => true do |t|
    t.string   "name"
    t.integer  "level"
    t.boolean  "location_required", :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "searches", :force => true do |t|
    t.string   "query"
    t.string   "class_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "settables", :force => true do |t|
    t.string   "key"
    t.string   "name"
    t.string   "description"
    t.string   "default"
    t.string   "kind"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "settings", :force => true do |t|
    t.integer  "settable_id"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "translations", :force => true do |t|
    t.integer  "language_id"
    t.text     "str"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "fld"
    t.string   "class_name"
    t.integer  "obj_id"
  end

  add_index "translations", ["language_id", "class_name", "fld", "obj_id"], :name => "translation_master", :unique => true

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email"
    t.integer  "language_id"
    t.integer  "role_id"
    t.integer  "location_id"
    t.string   "phone"
    t.boolean  "is_mobile_phone",     :default => false
    t.boolean  "active",              :default => false
    t.string   "password_salt"
    t.string   "crypted_password"
    t.string   "single_access_token"
    t.string   "perishable_token"
    t.string   "persistence_token"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "login_count",         :default => 0
    t.string   "device"
    t.text     "notes"
  end

  add_index "users", ["login"], :name => "index_users_on_login", :unique => true

end
