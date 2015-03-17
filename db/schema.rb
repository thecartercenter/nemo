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

ActiveRecord::Schema.define(:version => 20150311134337) do

  create_table "answers", :force => true do |t|
    t.integer  "response_id"
    t.integer  "option_id"
    t.text     "value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "questioning_id"
    t.time     "time_value"
    t.date     "date_value"
    t.datetime "datetime_value"
    t.boolean  "delta",          :default => true, :null => false
    t.integer  "rank"
  end

  add_index "answers", ["option_id"], :name => "answers_option_id_fk"
  add_index "answers", ["questioning_id"], :name => "answers_questioning_id_fk"
  add_index "answers", ["response_id"], :name => "answers_response_id_fk"

  create_table "assignments", :force => true do |t|
    t.integer  "mission_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "role"
  end

  add_index "assignments", ["mission_id"], :name => "assignments_mission_id_fk"
  add_index "assignments", ["user_id"], :name => "assignments_user_id_fk"

  create_table "broadcast_addressings", :force => true do |t|
    t.integer  "broadcast_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "broadcast_addressings", ["broadcast_id"], :name => "broadcast_addressings_broadcast_id_fk"
  add_index "broadcast_addressings", ["user_id"], :name => "broadcast_addressings_user_id_fk"

  create_table "broadcasts", :force => true do |t|
    t.string   "subject"
    t.text     "body"
    t.string   "medium"
    t.text     "send_errors"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "which_phone"
    t.integer  "mission_id"
  end

  add_index "broadcasts", ["mission_id"], :name => "broadcasts_mission_id_fk"

  create_table "choices", :force => true do |t|
    t.integer  "answer_id"
    t.integer  "option_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "choices", ["answer_id"], :name => "choices_answer_id_fk"
  add_index "choices", ["option_id"], :name => "choices_option_id_fk"

  create_table "conditions", :force => true do |t|
    t.integer  "questioning_id"
    t.integer  "ref_qing_id"
    t.string   "op"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "mission_id"
    t.string   "option_ids"
  end

  add_index "conditions", ["mission_id"], :name => "index_conditions_on_mission_id"
  add_index "conditions", ["questioning_id"], :name => "conditions_questioning_id_fk"
  add_index "conditions", ["ref_qing_id"], :name => "conditions_ref_qing_id_fk"

  create_table "form_items", :force => true do |t|
    t.integer  "question_id"
    t.integer  "form_id"
    t.integer  "rank"
    t.boolean  "required",                :default => false
    t.boolean  "hidden",                  :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "mission_id"
    t.string   "type"
    t.string   "ancestry"
    t.integer  "ancestry_depth"
    t.string   "group_name_translations"
  end

  add_index "form_items", ["ancestry"], :name => "index_form_items_on_ancestry"
  add_index "form_items", ["form_id"], :name => "questionings_form_id_fk"
  add_index "form_items", ["mission_id"], :name => "index_questionings_on_mission_id"
  add_index "form_items", ["question_id"], :name => "questionings_question_id_fk"

  create_table "form_versions", :force => true do |t|
    t.integer  "form_id"
    t.integer  "sequence",   :default => 1
    t.string   "code"
    t.boolean  "is_current", :default => true
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
  end

  add_index "form_versions", ["code"], :name => "index_form_versions_on_code", :unique => true
  add_index "form_versions", ["form_id"], :name => "form_versions_form_id_fk"

  create_table "forms", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "published",          :default => false
    t.integer  "downloads"
    t.integer  "responses_count",    :default => 0
    t.integer  "mission_id"
    t.integer  "current_version_id"
    t.boolean  "upgrade_needed",     :default => false
    t.boolean  "smsable",            :default => false
    t.boolean  "is_standard",        :default => false
    t.integer  "original_id"
    t.boolean  "allow_incomplete",   :default => false,     :null => false
    t.string   "access_level",       :default => "private", :null => false
    t.datetime "pub_changed_at"
    t.integer  "root_id"
    t.boolean  "standard_copy",      :default => false,     :null => false
  end

  add_index "forms", ["current_version_id"], :name => "forms_current_version_id_fk"
  add_index "forms", ["mission_id", "name"], :name => "index_forms_on_mission_id_and_name", :unique => true
  add_index "forms", ["original_id"], :name => "index_forms_on_standard_id"

  create_table "groups", :force => true do |t|
    t.string   "name",       :null => false
    t.integer  "mission_id", :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "groups", ["mission_id"], :name => "groups_mission_id_fk"

  create_table "missions", :force => true do |t|
    t.string   "name"
    t.string   "compact_name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "locked",       :default => false, :null => false
  end

  add_index "missions", ["compact_name"], :name => "index_missions_on_compact_name"

  create_table "option_nodes", :force => true do |t|
    t.string   "ancestry"
    t.integer  "option_set_id"
    t.integer  "option_id"
    t.integer  "rank",           :default => 1, :null => false
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
    t.integer  "mission_id"
    t.integer  "ancestry_depth", :default => 0
  end

  add_index "option_nodes", ["ancestry"], :name => "index_option_nodes_on_ancestry"
  add_index "option_nodes", ["mission_id"], :name => "option_nodes_mission_id_fk"
  add_index "option_nodes", ["option_id"], :name => "option_nodes_option_id_fk"
  add_index "option_nodes", ["option_set_id"], :name => "option_nodes_option_set_id_fk"
  add_index "option_nodes", ["rank"], :name => "index_option_nodes_on_rank"

  create_table "option_sets", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "mission_id"
    t.boolean  "is_standard",   :default => false
    t.integer  "original_id"
    t.boolean  "geographic",    :default => false, :null => false
    t.integer  "root_node_id"
    t.text     "level_names"
    t.boolean  "standard_copy", :default => false, :null => false
  end

  add_index "option_sets", ["geographic"], :name => "index_option_sets_on_geographic"
  add_index "option_sets", ["mission_id"], :name => "index_option_sets_on_mission_id"
  add_index "option_sets", ["original_id"], :name => "index_option_sets_on_standard_id"
  add_index "option_sets", ["root_node_id"], :name => "option_sets_root_node_id_fk"

  create_table "options", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "mission_id"
    t.string   "canonical_name"
    t.text     "name_translations"
  end

  add_index "options", ["canonical_name", "mission_id"], :name => "index_options_on_canonical_name_and_mission_id"
  add_index "options", ["mission_id"], :name => "index_options_on_mission_id"

  create_table "questions", :force => true do |t|
    t.string   "code"
    t.integer  "option_set_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "minimum",           :precision => 15, :scale => 10
    t.decimal  "maximum",           :precision => 15, :scale => 10
    t.boolean  "maxstrictly"
    t.boolean  "minstrictly"
    t.integer  "mission_id"
    t.string   "qtype_name"
    t.text     "canonical_name"
    t.text     "name_translations"
    t.text     "hint_translations"
    t.boolean  "key",                                               :default => false
    t.boolean  "is_standard",                                       :default => false
    t.integer  "original_id"
    t.string   "access_level",                                      :default => "inherit", :null => false
    t.boolean  "standard_copy",                                     :default => false,     :null => false
  end

  add_index "questions", ["mission_id", "code"], :name => "index_questions_on_mission_id_and_code", :unique => true
  add_index "questions", ["option_set_id"], :name => "questions_option_set_id_fk"
  add_index "questions", ["original_id"], :name => "index_questions_on_standard_id"
  add_index "questions", ["qtype_name"], :name => "index_questions_on_qtype_name"

  create_table "report_calculations", :force => true do |t|
    t.string   "type"
    t.integer  "report_report_id"
    t.integer  "question1_id"
    t.string   "attrib1_name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "rank"
  end

  add_index "report_calculations", ["question1_id"], :name => "report_calculations_question1_id_fk"
  add_index "report_calculations", ["report_report_id"], :name => "report_calculations_report_report_id_fk"

  create_table "report_option_set_choices", :force => true do |t|
    t.integer "report_report_id"
    t.integer "option_set_id"
  end

  add_index "report_option_set_choices", ["option_set_id"], :name => "report_option_set_choices_option_set_id_fk"
  add_index "report_option_set_choices", ["report_report_id"], :name => "report_option_set_choices_report_report_id_fk"

  create_table "report_reports", :force => true do |t|
    t.integer  "mission_id"
    t.string   "type"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "viewed_at"
    t.integer  "view_count",       :default => 0
    t.string   "display_type",     :default => "table"
    t.string   "bar_style",        :default => "side_by_side"
    t.boolean  "unreviewed",       :default => false
    t.string   "question_labels",  :default => "title"
    t.string   "percent_type",     :default => "none"
    t.boolean  "unique_rows",      :default => false
    t.string   "aggregation_name"
    t.integer  "form_id"
    t.string   "question_order",   :default => "number",       :null => false
    t.string   "text_responses",   :default => "all"
    t.integer  "disagg_qing_id"
    t.string   "filter"
    t.boolean  "group_by_tag",     :default => false,          :null => false
  end

  add_index "report_reports", ["disagg_qing_id"], :name => "report_reports_disagg_qing_id_fk"
  add_index "report_reports", ["form_id"], :name => "report_reports_form_id_fk"
  add_index "report_reports", ["mission_id"], :name => "report_reports_mission_id_fk"
  add_index "report_reports", ["view_count"], :name => "index_report_reports_on_view_count"

  create_table "responses", :force => true do |t|
    t.integer  "form_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "reviewed",          :default => false
    t.string   "source"
    t.integer  "mission_id"
    t.boolean  "incomplete",        :default => false, :null => false
    t.datetime "checked_out_at"
    t.integer  "checked_out_by_id"
  end

  add_index "responses", ["checked_out_at"], :name => "index_responses_on_checked_out_at"
  add_index "responses", ["checked_out_by_id"], :name => "responses_checked_out_by_id_fk"
  add_index "responses", ["created_at"], :name => "index_responses_on_created_at"
  add_index "responses", ["form_id"], :name => "responses_form_id_fk"
  add_index "responses", ["mission_id"], :name => "responses_mission_id_fk"
  add_index "responses", ["reviewed"], :name => "index_responses_on_reviewed"
  add_index "responses", ["updated_at"], :name => "index_responses_on_updated_at"
  add_index "responses", ["user_id"], :name => "responses_user_id_fk"

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "settings", :force => true do |t|
    t.string   "timezone"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "mission_id"
    t.string   "outgoing_sms_adapter"
    t.string   "intellisms_username"
    t.string   "intellisms_password"
    t.string   "incoming_sms_number"
    t.string   "preferred_locales"
    t.string   "override_code"
    t.boolean  "allow_unauthenticated_submissions", :default => false
  end

  add_index "settings", ["mission_id"], :name => "settings_mission_id_fk"

  create_table "sms_messages", :force => true do |t|
    t.string   "to"
    t.string   "from"
    t.text     "body"
    t.datetime "sent_at"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
    t.integer  "mission_id"
    t.string   "adapter_name"
    t.string   "type",         :null => false
    t.integer  "user_id"
    t.integer  "broadcast_id"
    t.integer  "reply_to_id"
  end

  add_index "sms_messages", ["body"], :name => "index_sms_messages_on_body", :length => {"body"=>160}
  add_index "sms_messages", ["broadcast_id"], :name => "sms_messages_broadcast_id_fk"
  add_index "sms_messages", ["created_at"], :name => "index_sms_messages_on_created_at"
  add_index "sms_messages", ["from"], :name => "index_sms_messages_on_from"
  add_index "sms_messages", ["mission_id"], :name => "sms_messages_mission_id_fk"
  add_index "sms_messages", ["reply_to_id"], :name => "sms_messages_reply_to_id_fk"
  add_index "sms_messages", ["to"], :name => "index_sms_messages_on_to"
  add_index "sms_messages", ["type"], :name => "index_sms_messages_on_type"
  add_index "sms_messages", ["user_id"], :name => "sms_messages_user_id_fk"

  create_table "taggings", :force => true do |t|
    t.integer  "question_id", :null => false
    t.integer  "tag_id",      :null => false
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "taggings", ["question_id"], :name => "index_taggings_on_question_id"
  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"

  create_table "tags", :force => true do |t|
    t.string   "name",       :limit => 64, :null => false
    t.integer  "mission_id"
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
  end

  add_index "tags", ["mission_id"], :name => "index_tags_on_mission_id"
  add_index "tags", ["name", "mission_id"], :name => "index_tags_on_name_and_mission_id"

  create_table "user_groups", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.integer  "group_id",   :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "user_groups", ["group_id"], :name => "user_groups_group_id_fk"
  add_index "user_groups", ["user_id"], :name => "user_groups_user_id_fk"

  create_table "users", :force => true do |t|
    t.string   "login",                                  :null => false
    t.string   "email"
    t.string   "phone"
    t.string   "password_salt"
    t.string   "crypted_password"
    t.string   "single_access_token"
    t.string   "perishable_token"
    t.string   "persistence_token"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
    t.integer  "login_count",         :default => 0
    t.text     "notes"
    t.datetime "last_request_at"
    t.string   "name",                                   :null => false
    t.string   "phone2"
    t.boolean  "admin",               :default => false, :null => false
    t.string   "pref_lang",                              :null => false
    t.string   "api_key"
    t.integer  "last_mission_id"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["login"], :name => "index_users_on_login", :unique => true
  add_index "users", ["name"], :name => "index_users_on_name"

  create_table "whitelists", :force => true do |t|
    t.integer  "user_id"
    t.integer  "whitelistable_id"
    t.string   "whitelistable_type"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
  end

  add_foreign_key "assignments", "missions", name: "assignments_mission_id_fk"
  add_foreign_key "assignments", "users", name: "assignments_user_id_fk"

  add_foreign_key "broadcast_addressings", "broadcasts", name: "broadcast_addressings_broadcast_id_fk"
  add_foreign_key "broadcast_addressings", "users", name: "broadcast_addressings_user_id_fk"

  add_foreign_key "broadcasts", "missions", name: "broadcasts_mission_id_fk"

  add_foreign_key "choices", "options", name: "choices_option_id_fk"

  add_foreign_key "conditions", "form_items", name: "conditions_questioning_id_fk", column: "questioning_id"
  add_foreign_key "conditions", "form_items", name: "conditions_ref_qing_id_fk", column: "ref_qing_id"
  add_foreign_key "conditions", "missions", name: "conditions_mission_id_fk"

  add_foreign_key "form_items", "forms", name: "questionings_form_id_fk"
  add_foreign_key "form_items", "missions", name: "questionings_mission_id_fk"
  add_foreign_key "form_items", "questions", name: "questionings_question_id_fk"

  add_foreign_key "form_versions", "forms", name: "form_versions_form_id_fk"

  add_foreign_key "forms", "form_versions", name: "forms_current_version_id_fk", column: "current_version_id", dependent: :nullify
  add_foreign_key "forms", "forms", name: "forms_standard_id_fk", column: "original_id"
  add_foreign_key "forms", "missions", name: "forms_mission_id_fk"

  add_foreign_key "groups", "missions", name: "groups_mission_id_fk"

  add_foreign_key "option_nodes", "missions", name: "option_nodes_mission_id_fk"
  add_foreign_key "option_nodes", "option_sets", name: "option_nodes_option_set_id_fk"
  add_foreign_key "option_nodes", "options", name: "option_nodes_option_id_fk"

  add_foreign_key "option_sets", "missions", name: "option_sets_mission_id_fk"
  add_foreign_key "option_sets", "option_nodes", name: "option_sets_root_node_id_fk", column: "root_node_id"
  add_foreign_key "option_sets", "option_sets", name: "option_sets_standard_id_fk", column: "original_id"

  add_foreign_key "options", "missions", name: "options_mission_id_fk"

  add_foreign_key "questions", "missions", name: "questions_mission_id_fk"
  add_foreign_key "questions", "option_sets", name: "questions_option_set_id_fk"
  add_foreign_key "questions", "questions", name: "questions_standard_id_fk", column: "original_id"

  add_foreign_key "report_calculations", "questions", name: "report_calculations_question1_id_fk", column: "question1_id"
  add_foreign_key "report_calculations", "report_reports", name: "report_calculations_report_report_id_fk"

  add_foreign_key "report_option_set_choices", "option_sets", name: "report_option_set_choices_option_set_id_fk"
  add_foreign_key "report_option_set_choices", "report_reports", name: "report_option_set_choices_report_report_id_fk"

  add_foreign_key "report_reports", "form_items", name: "report_reports_disagg_qing_id_fk", column: "disagg_qing_id"
  add_foreign_key "report_reports", "forms", name: "report_reports_form_id_fk"
  add_foreign_key "report_reports", "missions", name: "report_reports_mission_id_fk"

  add_foreign_key "responses", "forms", name: "responses_form_id_fk"
  add_foreign_key "responses", "missions", name: "responses_mission_id_fk"
  add_foreign_key "responses", "users", name: "responses_checked_out_by_id_fk", column: "checked_out_by_id"
  add_foreign_key "responses", "users", name: "responses_user_id_fk"

  add_foreign_key "settings", "missions", name: "settings_mission_id_fk"

  add_foreign_key "sms_messages", "broadcasts", name: "sms_messages_broadcast_id_fk"
  add_foreign_key "sms_messages", "missions", name: "sms_messages_mission_id_fk"
  add_foreign_key "sms_messages", "sms_messages", name: "sms_messages_reply_to_id_fk", column: "reply_to_id"
  add_foreign_key "sms_messages", "users", name: "sms_messages_user_id_fk"

  add_foreign_key "user_groups", "groups", name: "user_groups_group_id_fk"
  add_foreign_key "user_groups", "users", name: "user_groups_user_id_fk"

end
