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

ActiveRecord::Schema.define(:version => 20120110163625) do

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

  create_table "conditions", :force => true do |t|
    t.integer  "questioning_id"
    t.integer  "ref_qing_id"
    t.string   "op"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "option_id"
  end

  create_table "form_types", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "forms", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "published",    :default => false
    t.integer  "form_type_id"
    t.integer  "downloads"
  end

  create_table "languages", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "active",     :default => false
    t.string   "code"
  end

  create_table "option_sets", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "ordering"
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

  create_table "place_creators", :force => true do |t|
    t.integer  "place_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "place_types", :force => true do |t|
    t.string   "name"
    t.integer  "level"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "short_name"
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
    t.boolean  "temporary",                                     :default => false
    t.integer  "point_id"
    t.integer  "address_id"
    t.integer  "locality_id"
    t.integer  "state_id"
    t.integer  "country_id"
  end

  create_table "question_types", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "odk_name"
    t.string   "odk_tag"
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

  create_table "search_searches", :force => true do |t|
    t.text     "str"
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
    t.string   "email"
    t.integer  "language_id"
    t.integer  "role_id"
    t.integer  "location_id"
    t.string   "phone"
    t.boolean  "phone_is_mobile",     :default => false
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
    t.datetime "last_request_at"
    t.string   "name"
  end

  add_index "users", ["login"], :name => "index_users_on_login", :unique => true

  create_view "_answers", "select `r`.`id` AS `response_id`,`r`.`observed_at` AS `observation_time`,`r`.`reviewed` AS `is_reviewed`,`f`.`name` AS `form_name`,`ft`.`name` AS `form_type`,`q`.`code` AS `question_code`,`qtr`.`str` AS `question_name`,`qt`.`name` AS `question_type`,`u`.`name` AS `observer_name`,`plc`.`full_name` AS `place_full_name`,`pnt`.`long_name` AS `point`,`adr`.`long_name` AS `address`,`loc`.`long_name` AS `locality`,`sta`.`long_name` AS `state`,`cry`.`long_name` AS `country`,`plc`.`latitude` AS `latitude`,`plc`.`longitude` AS `longitude`,concat(`plc`.`latitude`,',',`plc`.`longitude`) AS `latitude_longitude`,`a`.`id` AS `answer_id`,`a`.`value` AS `answer_value`,ifnull(`aotr`.`str`,`cotr`.`str`) AS `choice_name`,ifnull(`ao`.`value`,`co`.`value`) AS `choice_value`,`os`.`name` AS `option_set` from ((((((((((((((((((((`answers` `a` left join `options` `ao` on((`a`.`option_id` = `ao`.`id`))) left join `translations` `aotr` on(((`aotr`.`obj_id` = `ao`.`id`) and (`aotr`.`fld` = 'name') and (`aotr`.`class_name` = 'Option') and (`aotr`.`language_id` = (select `languages`.`id` from `languages` where (`languages`.`code` = 'eng')))))) left join `choices` `c` on((`c`.`answer_id` = `a`.`id`))) left join `options` `co` on((`c`.`option_id` = `co`.`id`))) left join `translations` `cotr` on(((`cotr`.`obj_id` = `co`.`id`) and (`cotr`.`fld` = 'name') and (`cotr`.`class_name` = 'Option') and (`cotr`.`language_id` = (select `languages`.`id` from `languages` where (`languages`.`code` = 'eng')))))) join `responses` `r` on((`a`.`response_id` = `r`.`id`))) join `users` `u` on((`r`.`user_id` = `u`.`id`))) join `forms` `f` on((`r`.`form_id` = `f`.`id`))) join `form_types` `ft` on((`f`.`form_type_id` = `ft`.`id`))) left join `places` `plc` on((`r`.`place_id` = `plc`.`id`))) left join `places` `pnt` on((`plc`.`point_id` = `pnt`.`id`))) left join `places` `adr` on((`plc`.`address_id` = `adr`.`id`))) left join `places` `loc` on((`plc`.`locality_id` = `loc`.`id`))) left join `places` `sta` on((`plc`.`state_id` = `sta`.`id`))) left join `places` `cry` on((`plc`.`country_id` = `cry`.`id`))) join `questionings` `qing` on((`a`.`questioning_id` = `qing`.`id`))) join `questions` `q` on((`qing`.`question_id` = `q`.`id`))) join `question_types` `qt` on((`q`.`question_type_id` = `qt`.`id`))) left join `option_sets` `os` on((`q`.`option_set_id` = `os`.`id`))) join `translations` `qtr` on(((`qtr`.`obj_id` = `q`.`id`) and (`qtr`.`fld` = 'name') and (`qtr`.`class_name` = 'Question') and (`qtr`.`language_id` = (select `languages`.`id` from `languages` where (`languages`.`code` = 'eng'))))))", :force => true do |v|
    v.column :response_id
    v.column :observation_time
    v.column :is_reviewed
    v.column :form_name
    v.column :form_type
    v.column :question_code
    v.column :question_name
    v.column :question_type
    v.column :observer_name
    v.column :place_full_name
    v.column :point
    v.column :address
    v.column :locality
    v.column :state
    v.column :country
    v.column :latitude
    v.column :longitude
    v.column :latitude_longitude
    v.column :answer_id
    v.column :answer_value
    v.column :choice_name
    v.column :choice_value
    v.column :option_set
  end

end
