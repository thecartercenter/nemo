# frozen_string_literal: true

class AddManyNullFalse < ActiveRecord::Migration[5.2]
  def up # rubocop:disable Metrics/MethodLength, Metrics/AbcSize -- comprehension not an issue
    puts("************************************************************************")
    puts("************************************************************************")
    puts("This migration sets NULL constraints on a lot of database columns")
    puts("There should not be any NULL values in any of them. If the migration fails due to")
    puts("NULL values existing in one or more columns, you will need to manually delete them.")
    puts("Inspecting them beforehand to ensure the deletion is OK is a good idea.")
    puts("************************************************************************")
    puts("************************************************************************")
    change_column_null :assignments, :mission_id, false
    change_column_null :assignments, :role, false
    change_column_null :assignments, :user_id, false
    change_column_null :broadcast_addressings, :addressee_id, false
    execute("DELETE FROM broadcast_addressings WHERE broadcast_id IS NULL")
    change_column_null :broadcast_addressings, :broadcast_id, false
    execute("DELETE FROM broadcasts WHERE medium IS NULL")
    change_column_null :broadcasts, :medium, false
    execute("DELETE FROM broadcasts WHERE mission_id IS NULL")
    change_column_null :broadcasts, :mission_id, false
    change_column_null :broadcasts, :body, false
    change_column_null :conditions, :conditionable_type, false
    change_column_null :conditions, :op, false
    change_column_null :form_forwardings, :form_id, false
    change_column_null :form_forwardings, :recipient_id, false
    change_column_null :form_forwardings, :recipient_type, false
    change_column_null :form_items, :form_id, false
    change_column_null :form_versions, :code, false
    change_column_null :form_versions, :form_id, false
    change_column_null :form_versions, :is_current, false
    change_column_null :form_versions, :sequence, false
    change_column_null :forms, :authenticate_sms, false
    change_column_null :forms, :is_standard, false
    change_column_null :forms, :name, false
    change_column_null :forms, :published, false
    change_column_null :forms, :smsable, false
    change_column_null :forms, :upgrade_needed, false
    change_column_null :media_objects, :item_content_type, false
    change_column_null :media_objects, :item_file_name, false
    change_column_null :media_objects, :item_file_size, false
    change_column_null :media_objects, :item_updated_at, false
    change_column_null :media_objects, :type, false
    change_column_null :missions, :compact_name, false
    change_column_null :missions, :name, false
    change_column_null :operations, :creator_id, false
    change_column_comment :operations, :mission_id, "Operations are possible in admin mode"
    change_column_null :option_nodes, :ancestry_depth, false
    change_column_null :option_nodes, :is_standard, false
    change_column_null :option_nodes, :option_set_id, false
    change_column_default :option_nodes, :sequence, 0
    execute("UPDATE option_nodes SET sequence = 0 WHERE sequence IS NULL")
    change_column_null :option_nodes, :sequence, false
    change_column_null :option_sets, :is_standard, false
    change_column_null :option_sets, :name, false
    change_column_null :options, :name_translations, false
    change_column_null :questions, :code, false
    change_column_null :questions, :is_standard, false
    change_column_null :questions, :key, false
    change_column_null :questions, :name_translations, false
    change_column_null :questions, :qtype_name, false
    change_column_default :report_calculations, :rank, 1
    execute("UPDATE report_calculations SET rank = 1 WHERE rank IS NULL")
    change_column_null :report_calculations, :rank, false
    execute("DELETE FROM report_calculations WHERE report_report_id IS NULL")
    change_column_null :report_calculations, :report_report_id, false
    change_column_null :report_calculations, :type, false
    execute("DELETE FROM report_option_set_choices WHERE option_set_id IS NULL")
    change_column_null :report_option_set_choices, :option_set_id, false
    execute("DELETE FROM report_option_set_choices WHERE report_report_id IS NULL")
    change_column_null :report_option_set_choices, :report_report_id, false
    change_column_null :report_reports, :mission_id, false
    change_column_null :report_reports, :name, false
    change_column_null :report_reports, :type, false
    change_column_null :report_reports, :view_count, false
    change_column_null :responses, :form_id, false
    change_column_null :responses, :mission_id, false
    change_column_null :responses, :reviewed, false
    change_column_null :responses, :source, false
    change_column_null :responses, :user_id, false
    change_column_null :saved_uploads, :file_content_type, false
    change_column_null :saved_uploads, :file_file_name, false
    change_column_null :saved_uploads, :file_file_size, false
    change_column_null :saved_uploads, :file_updated_at, false
    change_column_null :settings, :preferred_locales, false
    change_column_null :settings, :timezone, false
    execute("UPDATE sms_messages SET adapter_name = 'FrontlineSms' WHERE adapter_name IS NULL")
    change_column_null :sms_messages, :adapter_name, false
    change_column_null :sms_messages, :body, false
    change_column_comment :sms_messages, :mission_id,
      "Can't set null false due to missionless SMS receive flow"
    change_column_null :sms_messages, :sent_at, false
    change_column_null :taggings, :question_id, false
    change_column_comment :taggings, :tag_id, "Can't set null false due to replication process"
    change_column_null :user_group_assignments, :user_group_id, false
    change_column_null :user_group_assignments, :user_id, false
    change_column_null :user_groups, :mission_id, false
    change_column_null :users, :crypted_password, false
    execute("UPDATE users SET login_count = 0 WHERE login_count IS NULL")
    change_column_null :users, :login_count, false
    change_column_null :users, :password_salt, false

    change_column_null :answers, :created_at, false
    change_column_null :assignments, :created_at, false
    change_column_null :broadcast_addressings, :created_at, false
    change_column_null :broadcasts, :created_at, false
    change_column_null :choices, :created_at, false
    change_column_null :conditions, :created_at, false
    change_column_null :delayed_jobs, :created_at, false
    change_column_null :form_items, :created_at, false
    change_column_null :forms, :created_at, false
    change_column_null :missions, :created_at, false
    change_column_null :option_sets, :created_at, false
    change_column_null :options, :created_at, false
    change_column_null :questions, :created_at, false
    change_column_null :report_calculations, :created_at, false
    change_column_null :report_reports, :created_at, false
    change_column_null :responses, :created_at, false
    change_column_null :sessions, :created_at, false
    change_column_null :settings, :created_at, false

    change_column_null :answers, :updated_at, false
    change_column_null :assignments, :updated_at, false
    change_column_null :broadcast_addressings, :updated_at, false
    change_column_null :broadcasts, :updated_at, false
    change_column_null :choices, :updated_at, false
    change_column_null :conditions, :updated_at, false
    change_column_null :delayed_jobs, :updated_at, false
    change_column_null :form_items, :updated_at, false
    change_column_null :forms, :updated_at, false
    change_column_null :missions, :updated_at, false
    change_column_null :option_sets, :updated_at, false
    change_column_null :options, :updated_at, false
    change_column_null :questions, :updated_at, false
    change_column_null :report_calculations, :updated_at, false
    change_column_null :report_reports, :updated_at, false
    change_column_null :responses, :updated_at, false
    change_column_null :sessions, :updated_at, false
    change_column_null :settings, :updated_at, false
  end
end
