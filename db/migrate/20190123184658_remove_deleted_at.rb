# frozen_string_literal: true

class RemoveDeletedAt < ActiveRecord::Migration[5.2]
  TABLES = %i[
    choices
    media_objects
    answers
    assignments
    conditions
    form_versions
    option_nodes
    options
    report_calculations
    report_option_set_choices
    report_reports
    option_sets
    responses
    skip_rules
    form_items
    forms
    taggings
    tags
    questions
    user_group_assignments
    user_groups
    users
    missions
  ].freeze

  def up
    execute("UPDATE forms SET root_id = NULL WHERE deleted_at IS NOT NULL")
    execute("UPDATE forms SET current_version_id = NULL WHERE deleted_at IS NOT NULL")
    execute("UPDATE questions SET option_set_id = NULL WHERE deleted_at IS NOT NULL")
    execute("UPDATE option_sets SET root_node_id = NULL WHERE deleted_at IS NOT NULL")
    execute("UPDATE users SET last_mission_id = NULL WHERE EXISTS
      (SELECT * FROM missions WHERE deleted_at IS NOT NULL AND id = users.last_mission_id)")
    TABLES.each { |t| execute("DELETE FROM #{t} WHERE deleted_at IS NOT NULL") }

    remove_index :answers, %w[deleted_at type]
    add_index :answers, %w[type]

    remove_unique_indices_dependent_on_deleted_at
    reinstate_unique_indices

    TABLES.each { |t| remove_column t, :deleted_at }
  end

  private

  def remove_unique_indices_dependent_on_deleted_at # rubocop:disable Metrics/MethodLength
    remove_index :assignments, %w[mission_id user_id]
    remove_index :form_items, %w[form_id question_id]
    remove_index :form_versions, ["code"]
    remove_index :forms, ["root_id"]
    remove_index :missions, ["compact_name"]
    remove_index :missions, ["shortcode"]
    remove_index :option_sets, ["root_node_id"]
    remove_index :questions, %w[mission_id code]
    remove_index :responses, %w[form_id odk_hash]
    remove_index :responses, ["shortcode"]
    remove_index :tags, %w[name mission_id]
    remove_index :user_group_assignments, %w[user_id user_group_id]
    remove_index :user_groups, %w[name mission_id]
    remove_index :users, ["login"]
    remove_index :users, ["sms_auth_code"]
  end

  def reinstate_unique_indices # rubocop:disable Metrics/MethodLength
    add_index :assignments, %w[mission_id user_id], unique: true
    add_index :form_items, %w[form_id question_id], unique: true
    add_index :form_versions, ["code"], unique: true
    add_index :forms, ["root_id"], unique: true
    add_index :missions, ["compact_name"], unique: true
    add_index :missions, ["shortcode"], unique: true
    add_index :option_sets, ["root_node_id"], unique: true
    add_index :questions, %w[mission_id code], unique: true
    add_index :responses, %w[form_id odk_hash], unique: true
    add_index :responses, ["shortcode"], unique: true
    add_index :tags, %w[name mission_id], unique: true
    add_index :user_group_assignments, %w[user_id user_group_id], unique: true
    add_index :user_groups, %w[name mission_id], unique: true
    add_index :users, ["login"], unique: true
    add_index :users, ["sms_auth_code"], unique: true
  end
end
