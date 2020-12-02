# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_12_09_194945) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "answer_hierarchies", id: false, force: :cascade do |t|
    t.uuid "ancestor_id", null: false
    t.uuid "descendant_id", null: false
    t.integer "generations", null: false
    t.index ["ancestor_id", "descendant_id"], name: "index_answer_hierarchies_on_ancestor_id_and_descendant_id", unique: true
    t.index ["descendant_id"], name: "answer_desc_idx"
  end

  create_table "answers", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.decimal "accuracy", precision: 9, scale: 3
    t.decimal "altitude", precision: 9, scale: 3
    t.datetime "created_at", null: false
    t.date "date_value"
    t.datetime "datetime_value"
    t.decimal "latitude", precision: 8, scale: 6
    t.decimal "longitude", precision: 9, scale: 6
    t.uuid "mission_id", null: false
    t.integer "new_rank", default: 0, null: false
    t.integer "old_inst_num", default: 1, null: false
    t.integer "old_rank", default: 1, null: false
    t.uuid "option_node_id"
    t.uuid "parent_id"
    t.string "pending_file_name"
    t.uuid "questioning_id", null: false
    t.uuid "response_id", null: false
    t.time "time_value"
    t.tsvector "tsv"
    t.string "type", default: "Answer", null: false
    t.datetime "updated_at", null: false
    t.text "value"
    t.index ["mission_id"], name: "index_answers_on_mission_id"
    t.index ["new_rank"], name: "index_answers_on_new_rank"
    t.index ["option_node_id"], name: "index_answers_on_option_node_id"
    t.index ["parent_id"], name: "index_answers_on_parent_id"
    t.index ["questioning_id"], name: "index_answers_on_questioning_id"
    t.index ["response_id"], name: "index_answers_on_response_id"
    t.index ["type"], name: "index_answers_on_type"
  end

  create_table "assignments", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "mission_id", null: false
    t.string "role", limit: 255, null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["mission_id", "user_id"], name: "index_assignments_on_mission_id_and_user_id", unique: true
    t.index ["mission_id"], name: "index_assignments_on_mission_id"
    t.index ["user_id"], name: "index_assignments_on_user_id"
  end

  create_table "broadcast_addressings", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "addressee_id", null: false
    t.string "addressee_type", limit: 255, null: false
    t.uuid "broadcast_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["addressee_id"], name: "index_broadcast_addressings_on_addressee_id"
    t.index ["broadcast_id"], name: "index_broadcast_addressings_on_broadcast_id"
  end

  create_table "broadcasts", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.string "medium", limit: 255, null: false
    t.uuid "mission_id", null: false
    t.string "recipient_selection", limit: 255, null: false
    t.text "send_errors"
    t.datetime "sent_at"
    t.string "source", limit: 255, default: "manual", null: false
    t.string "subject", limit: 255
    t.datetime "updated_at", null: false
    t.string "which_phone", limit: 255
    t.index ["mission_id"], name: "index_broadcasts_on_mission_id"
  end

  create_table "choices", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "answer_id", null: false
    t.datetime "created_at", null: false
    t.decimal "latitude", precision: 8, scale: 6
    t.decimal "longitude", precision: 9, scale: 6
    t.uuid "option_node_id"
    t.datetime "updated_at", null: false
    t.index ["answer_id"], name: "index_choices_on_answer_id"
    t.index ["option_node_id"], name: "index_choices_on_option_node_id"
  end

  create_table "conditions", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "conditionable_id", null: false
    t.string "conditionable_type", null: false
    t.datetime "created_at", null: false
    t.uuid "left_qing_id", null: false
    t.uuid "mission_id"
    t.string "op", limit: 255, null: false
    t.uuid "option_node_id"
    t.integer "rank", null: false
    t.uuid "right_qing_id"
    t.datetime "updated_at", null: false
    t.string "value", limit: 255
    t.index ["conditionable_id"], name: "index_conditions_on_conditionable_id"
    t.index ["conditionable_type", "conditionable_id"], name: "index_conditions_on_conditionable_type_and_conditionable_id"
    t.index ["left_qing_id"], name: "index_conditions_on_left_qing_id"
    t.index ["mission_id"], name: "index_conditions_on_mission_id"
    t.index ["option_node_id"], name: "index_conditions_on_option_node_id"
  end

  create_table "constraints", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "accept_if", limit: 16, default: "all_met", null: false
    t.datetime "created_at", null: false
    t.uuid "mission_id"
    t.integer "rank", null: false
    t.jsonb "rejection_msg_translations", default: {}
    t.uuid "source_item_id", null: false
    t.datetime "updated_at", null: false
    t.index ["mission_id"], name: "index_constraints_on_mission_id"
    t.index ["source_item_id", "rank"], name: "index_constraints_on_source_item_id_and_rank", unique: true
    t.index ["source_item_id"], name: "index_constraints_on_source_item_id"
  end

  create_table "delayed_jobs", id: :serial, force: :cascade do |t|
    t.integer "attempts", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "failed_at"
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "locked_at"
    t.string "locked_by", limit: 255
    t.integer "priority", default: 0, null: false
    t.string "queue", limit: 255
    t.datetime "run_at"
    t.datetime "updated_at", null: false
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "form_forwardings", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "form_id", null: false
    t.uuid "recipient_id", null: false
    t.string "recipient_type", limit: 255, null: false
    t.datetime "updated_at", null: false
    t.index ["form_id", "recipient_id", "recipient_type"], name: "form_forwardings_full", unique: true
    t.index ["form_id"], name: "index_form_forwardings_on_form_id"
    t.index ["recipient_id"], name: "index_form_forwardings_on_recipient_id"
  end

  create_table "form_items", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.boolean "all_levels_required", default: false, null: false
    t.text "ancestry"
    t.integer "ancestry_depth", null: false
    t.datetime "created_at", null: false
    t.string "default"
    t.boolean "disabled", default: false, null: false
    t.string "display_if", default: "always", null: false
    t.uuid "form_id", null: false
    t.integer "form_old_id"
    t.jsonb "group_hint_translations", default: {}
    t.jsonb "group_item_name_translations", default: {}
    t.jsonb "group_name_translations", default: {}
    t.boolean "hidden", default: false, null: false
    t.uuid "mission_id"
    t.integer "old_id"
    t.boolean "one_screen"
    t.boolean "preload_last_saved", default: false, null: false
    t.uuid "question_id"
    t.integer "question_old_id"
    t.integer "rank", null: false
    t.boolean "read_only"
    t.boolean "repeatable"
    t.boolean "required", default: false, null: false
    t.string "type", limit: 255, null: false
    t.datetime "updated_at", null: false
    t.index ["ancestry"], name: "index_form_items_on_ancestry"
    t.index ["form_id", "question_id"], name: "index_form_items_on_form_id_and_question_id", unique: true
    t.index ["form_id"], name: "index_form_items_on_form_id"
    t.index ["mission_id"], name: "index_form_items_on_mission_id"
    t.index ["question_id"], name: "index_form_items_on_question_id"
  end

  create_table "form_versions", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "code", limit: 255, null: false
    t.datetime "created_at", null: false
    t.boolean "current", default: true, null: false
    t.uuid "form_id", null: false
    t.boolean "minimum", default: true, null: false
    t.string "number", limit: 10, null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_form_versions_on_code", unique: true
    t.index ["form_id", "number"], name: "index_form_versions_on_form_id_and_number", unique: true
    t.index ["form_id"], name: "index_form_versions_on_form_id"
  end

  create_table "forms", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "access_level", limit: 255, default: "private", null: false
    t.boolean "allow_incomplete", default: false, null: false
    t.boolean "authenticate_sms", default: true, null: false
    t.datetime "created_at", null: false
    t.string "default_response_name"
    t.integer "downloads"
    t.uuid "mission_id"
    t.string "name", limit: 255, null: false
    t.uuid "original_id"
    t.datetime "published_changed_at"
    t.uuid "root_id"
    t.boolean "sms_relay", default: false, null: false
    t.boolean "smsable", default: false, null: false
    t.boolean "standard_copy", default: false, null: false
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.index ["mission_id"], name: "index_forms_on_mission_id"
    t.index ["original_id"], name: "index_forms_on_original_id"
    t.index ["root_id"], name: "index_forms_on_root_id", unique: true
    t.index ["status"], name: "index_forms_on_status"
  end

  create_table "media_objects", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "answer_id"
    t.datetime "created_at", null: false
    t.string "item_content_type", limit: 255, null: false
    t.string "item_file_name", limit: 255, null: false
    t.integer "item_file_size", null: false
    t.datetime "item_updated_at", null: false
    t.string "type", limit: 255, null: false
    t.datetime "updated_at", null: false
    t.index ["answer_id"], name: "index_media_objects_on_answer_id"
  end

  create_table "missions", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "compact_name", limit: 255, null: false
    t.datetime "created_at", null: false
    t.boolean "locked", default: false, null: false
    t.string "name", limit: 255, null: false
    t.string "shortcode", limit: 255, null: false
    t.datetime "updated_at", null: false
    t.index ["compact_name"], name: "index_missions_on_compact_name", unique: true
    t.index ["shortcode"], name: "index_missions_on_shortcode", unique: true
  end

  create_table "operations", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "attachment_content_type"
    t.string "attachment_download_name"
    t.string "attachment_file_name"
    t.integer "attachment_file_size"
    t.datetime "attachment_updated_at"
    t.datetime "created_at", null: false
    t.uuid "creator_id"
    t.string "details", limit: 255, null: false
    t.string "job_class", limit: 255, null: false
    t.datetime "job_completed_at"
    t.text "job_error_report"
    t.datetime "job_failed_at"
    t.string "job_id", limit: 255
    t.datetime "job_started_at"
    t.uuid "mission_id", comment: "Operations are possible in admin mode"
    t.string "notes", limit: 255
    t.string "provider_job_id", limit: 255
    t.boolean "unread", default: true, null: false
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["created_at"], name: "index_operations_on_created_at"
    t.index ["creator_id"], name: "index_operations_on_creator_id"
    t.index ["mission_id"], name: "index_operations_on_mission_id"
  end

  create_table "option_nodes", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.text "ancestry"
    t.integer "ancestry_depth", default: 0, null: false
    t.datetime "created_at", null: false
    t.uuid "mission_id"
    t.integer "old_id"
    t.uuid "option_id"
    t.uuid "option_set_id", null: false
    t.uuid "original_id"
    t.integer "rank", default: 1, null: false
    t.integer "sequence", default: 0, null: false
    t.boolean "standard_copy", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["ancestry"], name: "index_option_nodes_on_ancestry"
    t.index ["mission_id"], name: "index_option_nodes_on_mission_id"
    t.index ["option_id"], name: "index_option_nodes_on_option_id"
    t.index ["option_set_id"], name: "index_option_nodes_on_option_set_id"
    t.index ["original_id"], name: "index_option_nodes_on_original_id"
    t.index ["rank"], name: "index_option_nodes_on_rank"
  end

  create_table "option_sets", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.boolean "allow_coordinates", default: false, null: false
    t.datetime "created_at", null: false
    t.boolean "geographic", default: false, null: false
    t.jsonb "level_names"
    t.uuid "mission_id"
    t.string "name", limit: 255, null: false
    t.uuid "original_id"
    t.uuid "root_node_id"
    t.string "sms_guide_formatting", limit: 255, default: "auto", null: false
    t.boolean "standard_copy", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["geographic"], name: "index_option_sets_on_geographic"
    t.index ["mission_id"], name: "index_option_sets_on_mission_id"
    t.index ["original_id"], name: "index_option_sets_on_original_id"
    t.index ["root_node_id"], name: "index_option_sets_on_root_node_id", unique: true
  end

  create_table "options", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "canonical_name", limit: 255, null: false
    t.datetime "created_at", null: false
    t.decimal "latitude", precision: 8, scale: 6
    t.decimal "longitude", precision: 9, scale: 6
    t.uuid "mission_id"
    t.jsonb "name_translations", default: {}, null: false
    t.datetime "updated_at", null: false
    t.integer "value"
    t.index ["canonical_name"], name: "index_options_on_canonical_name"
    t.index ["mission_id"], name: "index_options_on_mission_id"
    t.index ["name_translations"], name: "index_options_on_name_translations", using: :gin
  end

  create_table "questions", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "access_level", limit: 255, default: "inherit", null: false
    t.boolean "auto_increment", default: false, null: false
    t.text "canonical_name", null: false
    t.string "code", limit: 255, null: false
    t.datetime "created_at", null: false
    t.jsonb "hint_translations", default: {}
    t.boolean "key", default: false, null: false
    t.decimal "maximum", precision: 15, scale: 8
    t.boolean "maxstrictly"
    t.string "media_prompt_content_type"
    t.string "media_prompt_file_name"
    t.integer "media_prompt_file_size"
    t.datetime "media_prompt_updated_at"
    t.string "metadata_type"
    t.decimal "minimum", precision: 15, scale: 8
    t.boolean "minstrictly"
    t.uuid "mission_id"
    t.jsonb "name_translations", default: {}, null: false
    t.uuid "option_set_id"
    t.uuid "original_id"
    t.string "qtype_name", limit: 255, null: false
    t.string "reference"
    t.boolean "standard_copy", default: false, null: false
    t.boolean "text_type_for_sms", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["mission_id", "code"], name: "index_questions_on_mission_id_and_code", unique: true
    t.index ["mission_id"], name: "index_questions_on_mission_id"
    t.index ["option_set_id"], name: "index_questions_on_option_set_id"
    t.index ["original_id"], name: "index_questions_on_original_id"
    t.index ["qtype_name"], name: "index_questions_on_qtype_name"
  end

  create_table "report_calculations", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "attrib1_name", limit: 255
    t.datetime "created_at", null: false
    t.uuid "question1_id"
    t.integer "rank", default: 1, null: false
    t.uuid "report_report_id", null: false
    t.string "type", limit: 255, null: false
    t.datetime "updated_at", null: false
    t.index ["question1_id"], name: "index_report_calculations_on_question1_id"
    t.index ["report_report_id"], name: "index_report_calculations_on_report_report_id"
  end

  create_table "report_option_set_choices", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "option_set_id", null: false
    t.uuid "report_report_id", null: false
    t.index ["option_set_id", "report_report_id"], name: "report_option_set_choice_unique", unique: true
    t.index ["option_set_id"], name: "index_report_option_set_choices_on_option_set_id"
    t.index ["report_report_id"], name: "index_report_option_set_choices_on_report_report_id"
  end

  create_table "report_reports", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "aggregation_name", limit: 255
    t.string "bar_style", limit: 255, default: "side_by_side"
    t.datetime "created_at", null: false
    t.uuid "creator_id"
    t.uuid "disagg_qing_id"
    t.string "display_type", limit: 255, default: "table"
    t.text "filter"
    t.uuid "form_id"
    t.boolean "group_by_tag", default: false, null: false
    t.uuid "mission_id", null: false
    t.string "name", limit: 255, null: false
    t.string "percent_type", limit: 255, default: "none"
    t.string "question_labels", limit: 255, default: "title"
    t.string "question_order", limit: 255, default: "number", null: false
    t.string "text_responses", limit: 255, default: "all"
    t.string "type", limit: 255, null: false
    t.boolean "unique_rows", default: false
    t.boolean "unreviewed", default: false
    t.datetime "updated_at", null: false
    t.integer "view_count", default: 0, null: false
    t.datetime "viewed_at"
    t.index ["creator_id"], name: "index_report_reports_on_creator_id"
    t.index ["disagg_qing_id"], name: "index_report_reports_on_disagg_qing_id"
    t.index ["form_id"], name: "index_report_reports_on_form_id"
    t.index ["mission_id"], name: "index_report_reports_on_mission_id"
    t.index ["view_count"], name: "index_report_reports_on_view_count"
  end

  create_table "responses", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.jsonb "cached_json"
    t.datetime "checked_out_at"
    t.uuid "checked_out_by_id"
    t.datetime "created_at", null: false
    t.string "device_id"
    t.boolean "dirty_json", default: true, null: false
    t.uuid "form_id", null: false
    t.boolean "incomplete", default: false, null: false
    t.uuid "mission_id", null: false
    t.string "odk_hash", limit: 255
    t.text "odk_xml"
    t.string "odk_xml_content_type"
    t.string "odk_xml_file_name"
    t.bigint "odk_xml_file_size"
    t.datetime "odk_xml_updated_at"
    t.integer "old_id"
    t.boolean "reviewed", default: false, null: false
    t.uuid "reviewer_id"
    t.text "reviewer_notes"
    t.string "shortcode", limit: 255, null: false
    t.string "source", limit: 255, null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["checked_out_at"], name: "index_responses_on_checked_out_at"
    t.index ["checked_out_by_id"], name: "index_responses_on_checked_out_by_id"
    t.index ["created_at"], name: "index_responses_on_created_at"
    t.index ["form_id", "odk_hash"], name: "index_responses_on_form_id_and_odk_hash", unique: true
    t.index ["form_id"], name: "index_responses_on_form_id"
    t.index ["mission_id"], name: "index_responses_on_mission_id"
    t.index ["reviewed"], name: "index_responses_on_reviewed"
    t.index ["reviewer_id"], name: "index_responses_on_reviewer_id"
    t.index ["shortcode"], name: "index_responses_on_shortcode", unique: true
    t.index ["updated_at"], name: "index_responses_on_updated_at"
    t.index ["user_id", "form_id"], name: "index_responses_on_user_id_and_form_id"
    t.index ["user_id"], name: "index_responses_on_user_id"
  end

  create_table "saved_uploads", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "file_content_type", null: false
    t.string "file_file_name", null: false
    t.integer "file_file_size", null: false
    t.datetime "file_updated_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sessions", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "data"
    t.string "session_id", limit: 255, null: false
    t.datetime "updated_at", null: false
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "settings", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "default_outgoing_sms_adapter", limit: 255
    t.string "frontlinecloud_api_key", limit: 255
    t.jsonb "generic_sms_config"
    t.text "incoming_sms_numbers"
    t.string "incoming_sms_token", limit: 255
    t.uuid "mission_id"
    t.string "override_code", limit: 255
    t.string "preferred_locales", limit: 255, null: false
    t.string "theme", default: "nemo", null: false
    t.string "timezone", limit: 255, null: false
    t.string "twilio_account_sid", limit: 255
    t.string "twilio_auth_token", limit: 255
    t.string "twilio_phone_number", limit: 255
    t.datetime "updated_at", null: false
    t.index ["mission_id"], name: "index_settings_on_mission_id", unique: true
  end

  create_table "skip_rules", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "dest_item_id"
    t.string "destination", null: false
    t.uuid "mission_id"
    t.integer "rank", null: false
    t.string "skip_if", null: false
    t.uuid "source_item_id", null: false
    t.datetime "updated_at", null: false
    t.index ["dest_item_id"], name: "index_skip_rules_on_dest_item_id"
    t.index ["source_item_id"], name: "index_skip_rules_on_source_item_id"
  end

  create_table "sms_messages", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "adapter_name", limit: 255, null: false
    t.boolean "auth_failed", default: false, null: false
    t.text "body", null: false
    t.uuid "broadcast_id"
    t.datetime "created_at", null: false
    t.string "from", limit: 255
    t.uuid "mission_id", comment: "Can't set null false due to missionless SMS receive flow"
    t.string "reply_error_message"
    t.uuid "reply_to_id"
    t.datetime "sent_at", null: false
    t.string "to", limit: 255
    t.string "type", limit: 255, null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.index ["body"], name: "index_sms_messages_on_body"
    t.index ["broadcast_id"], name: "index_sms_messages_on_broadcast_id"
    t.index ["created_at"], name: "index_sms_messages_on_created_at"
    t.index ["from"], name: "index_sms_messages_on_from"
    t.index ["mission_id"], name: "index_sms_messages_on_mission_id"
    t.index ["reply_to_id"], name: "index_sms_messages_on_reply_to_id"
    t.index ["to"], name: "index_sms_messages_on_to"
    t.index ["type"], name: "index_sms_messages_on_type"
    t.index ["user_id"], name: "index_sms_messages_on_user_id"
  end

  create_table "taggings", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "question_id", null: false
    t.uuid "tag_id", comment: "Can't set null false due to replication process"
    t.datetime "updated_at", null: false
    t.index ["question_id"], name: "index_taggings_on_question_id"
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
  end

  create_table "tags", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "mission_id"
    t.string "name", limit: 64, null: false
    t.datetime "updated_at", null: false
    t.index ["mission_id"], name: "index_tags_on_mission_id"
    t.index ["name", "mission_id"], name: "index_tags_on_name_and_mission_id", unique: true
  end

  create_table "user_group_assignments", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_group_id", null: false
    t.uuid "user_id", null: false
    t.index ["user_group_id"], name: "index_user_group_assignments_on_user_group_id"
    t.index ["user_id", "user_group_id"], name: "index_user_group_assignments_on_user_id_and_user_group_id", unique: true
    t.index ["user_id"], name: "index_user_group_assignments_on_user_id"
  end

  create_table "user_groups", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "mission_id", null: false
    t.string "name", limit: 255, null: false
    t.datetime "updated_at", null: false
    t.index ["mission_id"], name: "index_user_groups_on_mission_id"
    t.index ["name", "mission_id"], name: "index_user_groups_on_name_and_mission_id", unique: true
  end

  create_table "users", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.boolean "admin", default: false, null: false
    t.string "api_key", limit: 255
    t.integer "birth_year"
    t.datetime "created_at", null: false
    t.string "crypted_password", limit: 255, null: false
    t.datetime "current_login_at"
    t.string "email", limit: 255
    t.text "experience"
    t.string "gender", limit: 255
    t.string "gender_custom", limit: 255
    t.integer "import_num"
    t.uuid "last_mission_id"
    t.datetime "last_request_at"
    t.string "login", limit: 255, null: false
    t.integer "login_count", default: 0, null: false
    t.string "name", limit: 255, null: false
    t.string "nationality", limit: 255
    t.text "notes"
    t.string "password_salt", limit: 255, null: false
    t.string "perishable_token", limit: 255
    t.string "persistence_token", limit: 255
    t.string "phone", limit: 255
    t.string "phone2", limit: 255
    t.string "pref_lang", limit: 255, null: false
    t.string "sms_auth_code", limit: 255
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email"
    t.index ["last_mission_id"], name: "index_users_on_last_mission_id"
    t.index ["login"], name: "index_users_on_login", unique: true
    t.index ["name"], name: "index_users_on_name"
    t.index ["sms_auth_code"], name: "index_users_on_sms_auth_code", unique: true
  end

  create_table "whitelistings", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.uuid "whitelistable_id"
    t.string "whitelistable_type", limit: 255
    t.index ["user_id"], name: "index_whitelistings_on_user_id"
    t.index ["whitelistable_id"], name: "index_whitelistings_on_whitelistable_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "answer_hierarchies", "answers", column: "ancestor_id"
  add_foreign_key "answer_hierarchies", "answers", column: "descendant_id"
  add_foreign_key "answers", "form_items", column: "questioning_id", name: "answers_questioning_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "answers", "missions"
  add_foreign_key "answers", "option_nodes"
  add_foreign_key "answers", "responses", name: "answers_response_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "assignments", "missions", name: "assignments_mission_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "assignments", "users", name: "assignments_user_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "broadcast_addressings", "broadcasts", name: "broadcast_addressings_broadcast_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "broadcasts", "missions", name: "broadcasts_mission_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "choices", "answers", name: "choices_answer_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "choices", "option_nodes"
  add_foreign_key "conditions", "form_items", column: "left_qing_id"
  add_foreign_key "conditions", "form_items", column: "right_qing_id"
  add_foreign_key "conditions", "missions", name: "conditions_mission_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "conditions", "option_nodes", name: "conditions_option_node_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "constraints", "form_items", column: "source_item_id"
  add_foreign_key "constraints", "missions"
  add_foreign_key "form_forwardings", "forms", name: "form_forwardings_form_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "form_items", "forms", name: "form_items_form_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "form_items", "missions", name: "form_items_mission_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "form_items", "questions", name: "form_items_question_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "form_versions", "forms", name: "form_versions_form_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "forms", "form_items", column: "root_id", name: "forms_root_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "forms", "missions", name: "forms_mission_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "media_objects", "answers", name: "media_objects_answer_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "operations", "missions"
  add_foreign_key "operations", "users", column: "creator_id", name: "operations_creator_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "option_nodes", "missions", name: "option_nodes_mission_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "option_nodes", "option_sets", name: "option_nodes_option_set_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "option_nodes", "options", name: "option_nodes_option_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "option_sets", "missions", name: "option_sets_mission_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "option_sets", "option_nodes", column: "root_node_id", name: "option_sets_option_node_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "options", "missions", name: "options_mission_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "questions", "missions", name: "questions_mission_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "questions", "option_sets", name: "questions_option_set_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "report_calculations", "questions", column: "question1_id", name: "report_calculations_question1_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "report_calculations", "report_reports", name: "report_calculations_report_report_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "report_option_set_choices", "option_sets", name: "report_option_set_choices_option_set_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "report_option_set_choices", "report_reports", name: "report_option_set_choices_report_report_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "report_reports", "form_items", column: "disagg_qing_id", name: "report_reports_disagg_qing_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "report_reports", "forms", name: "report_reports_form_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "report_reports", "missions", name: "report_reports_mission_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "report_reports", "users", column: "creator_id", name: "report_reports_creator_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "responses", "forms", name: "responses_form_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "responses", "missions", name: "responses_mission_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "responses", "users", column: "checked_out_by_id", name: "responses_checked_out_by_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "responses", "users", column: "reviewer_id", name: "responses_reviewer_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "responses", "users", name: "responses_user_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "settings", "missions", name: "settings_mission_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "skip_rules", "form_items", column: "dest_item_id"
  add_foreign_key "skip_rules", "form_items", column: "source_item_id"
  add_foreign_key "sms_messages", "broadcasts", name: "sms_messages_broadcast_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "sms_messages", "missions", name: "sms_messages_mission_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "sms_messages", "sms_messages", column: "reply_to_id", name: "sms_messages_reply_to_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "sms_messages", "users", name: "sms_messages_user_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "taggings", "questions", name: "taggings_question_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "taggings", "tags", name: "taggings_tag_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "tags", "missions", name: "tags_mission_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "user_group_assignments", "user_groups", name: "user_group_assignments_user_group_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "user_group_assignments", "users", name: "user_group_assignments_user_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "user_groups", "missions", name: "user_groups_mission_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "users", "missions", column: "last_mission_id", name: "users_last_mission_id_fkey", on_update: :restrict, on_delete: :nullify
  add_foreign_key "whitelistings", "users", name: "whitelistings_user_id_fkey", on_update: :restrict, on_delete: :restrict
  create_trigger("answers_before_insert_update_row_tr", :generated => true, :compatibility => 1).
      on("answers").
      before(:insert, :update) do
    <<-SQL_ACTIONS
new.tsv :=         TO_TSVECTOR('simple', COALESCE(
          new.value,
          (SELECT STRING_AGG(opt_name_translation.value, ' ')
            FROM options, option_nodes, JSONB_EACH_TEXT(options.name_translations) opt_name_translation
            WHERE
              options.id = option_nodes.option_id
              AND (option_nodes.id = new.option_node_id
                OR option_nodes.id IN (SELECT option_node_id FROM choices WHERE answer_id = new.id))),
          ''
        ))
;
    SQL_ACTIONS
  end

end
