# frozen_string_literal: true

class ChangeForeignKeysToDeferrable < ActiveRecord::Migration[5.2]
  # rubocop:disable Metrics/LineLength, Metrics/AbcSize, Metrics/MethodLength
  def up
    remove_foreign_key "answers", name: "answers_questioning_id_fkey"
    remove_foreign_key "answers", "option_nodes"
    remove_foreign_key "answers", name: "answers_response_id_fkey"
    remove_foreign_key "assignments", name: "assignments_mission_id_fkey"
    remove_foreign_key "assignments", name: "assignments_user_id_fkey"
    remove_foreign_key "broadcast_addressings", name: "broadcast_addressings_broadcast_id_fkey"
    remove_foreign_key "broadcasts", name: "broadcasts_mission_id_fkey"
    remove_foreign_key "choices", name: "choices_answer_id_fkey"
    remove_foreign_key "choices", "option_nodes"
    remove_foreign_key "conditions", "form_items"
    remove_foreign_key "conditions", "form_items"
    remove_foreign_key "conditions", name: "conditions_mission_id_fkey"
    remove_foreign_key "conditions", name: "conditions_option_node_id_fkey"
    remove_foreign_key "constraints", "form_items"
    remove_foreign_key "constraints", "missions"
    remove_foreign_key "form_forwardings", name: "form_forwardings_form_id_fkey"
    remove_foreign_key "form_items", name: "form_items_form_id_fkey"
    remove_foreign_key "form_items", name: "form_items_mission_id_fkey"
    remove_foreign_key "form_items", name: "form_items_question_id_fkey"
    remove_foreign_key "form_versions", name: "form_versions_form_id_fkey"
    remove_foreign_key "forms", name: "forms_root_id_fkey"
    remove_foreign_key "forms", name: "forms_original_id_fkey"
    remove_foreign_key "forms", name: "forms_mission_id_fkey"
    remove_foreign_key "media_objects", name: "media_objects_answer_id_fkey"
    remove_foreign_key "operations", "missions"
    remove_foreign_key "operations", name: "operations_creator_id_fkey"
    remove_foreign_key "option_nodes", name: "option_nodes_mission_id_fkey"
    remove_foreign_key "option_nodes", name: "option_nodes_original_id_fkey"
    remove_foreign_key "option_nodes", name: "option_nodes_option_set_id_fkey"
    remove_foreign_key "option_nodes", name: "option_nodes_option_id_fkey"
    remove_foreign_key "option_sets", name: "option_sets_mission_id_fkey"
    remove_foreign_key "option_sets", name: "option_sets_option_node_id_fkey"
    remove_foreign_key "option_sets", name: "option_sets_original_id_fkey"
    remove_foreign_key "options", name: "options_mission_id_fkey"
    remove_foreign_key "questions", name: "questions_mission_id_fkey"
    remove_foreign_key "questions", name: "questions_option_set_id_fkey"
    remove_foreign_key "questions", name: "questions_original_id_fkey"
    remove_foreign_key "report_calculations", name: "report_calculations_question1_id_fkey"
    remove_foreign_key "report_calculations", name: "report_calculations_report_report_id_fkey"
    remove_foreign_key "report_option_set_choices", name: "report_option_set_choices_option_set_id_fkey"
    remove_foreign_key "report_option_set_choices", name: "report_option_set_choices_report_report_id_fkey"
    remove_foreign_key "report_reports", name: "report_reports_disagg_qing_id_fkey"
    remove_foreign_key "report_reports", name: "report_reports_form_id_fkey"
    remove_foreign_key "report_reports", name: "report_reports_mission_id_fkey"
    remove_foreign_key "report_reports", name: "report_reports_creator_id_fkey"
    remove_foreign_key "responses", name: "responses_form_id_fkey"
    remove_foreign_key "responses", name: "responses_mission_id_fkey"
    remove_foreign_key "responses", name: "responses_checked_out_by_id_fkey"
    remove_foreign_key "responses", name: "responses_reviewer_id_fkey"
    remove_foreign_key "responses", name: "responses_user_id_fkey"
    remove_foreign_key "settings", name: "settings_mission_id_fkey"
    remove_foreign_key "skip_rules", "form_items"
    remove_foreign_key "skip_rules", "form_items"
    remove_foreign_key "sms_messages", name: "sms_messages_broadcast_id_fkey"
    remove_foreign_key "sms_messages", name: "sms_messages_mission_id_fkey"
    remove_foreign_key "sms_messages", name: "sms_messages_reply_to_id_fkey"
    remove_foreign_key "sms_messages", name: "sms_messages_user_id_fkey"
    remove_foreign_key "taggings", name: "taggings_question_id_fkey"
    remove_foreign_key "taggings", name: "taggings_tag_id_fkey"
    remove_foreign_key "tags", name: "tags_mission_id_fkey"
    remove_foreign_key "user_group_assignments", name: "user_group_assignments_user_group_id_fkey"
    remove_foreign_key "user_group_assignments", name: "user_group_assignments_user_id_fkey"
    remove_foreign_key "user_groups", name: "user_groups_mission_id_fkey"
    remove_foreign_key "users", name: "users_last_mission_id_fkey"
    remove_foreign_key "whitelistings", name: "whitelistings_user_id_fkey"

    add_foreign_key "answers", "form_items", column: "questioning_id", deferrable: true
    add_foreign_key "answers", "option_nodes", deferrable: true
    add_foreign_key "answers", "responses", deferrable: true
    add_foreign_key "assignments", "missions", deferrable: true
    add_foreign_key "assignments", "users", deferrable: true
    add_foreign_key "broadcast_addressings", "broadcasts", deferrable: true
    add_foreign_key "broadcasts", "missions", deferrable: true
    add_foreign_key "choices", "answers", deferrable: true
    add_foreign_key "choices", "option_nodes", deferrable: true
    add_foreign_key "conditions", "form_items", column: "left_qing_id", deferrable: true
    add_foreign_key "conditions", "form_items", column: "right_qing_id", deferrable: true
    add_foreign_key "conditions", "missions", deferrable: true
    add_foreign_key "conditions", "option_nodes", deferrable: true
    add_foreign_key "constraints", "form_items", column: "source_item_id", deferrable: true
    add_foreign_key "constraints", "missions", deferrable: true
    add_foreign_key "form_forwardings", "forms", deferrable: true
    add_foreign_key "form_items", "forms", deferrable: true
    add_foreign_key "form_items", "missions", deferrable: true
    add_foreign_key "form_items", "questions", deferrable: true
    add_foreign_key "form_versions", "forms", deferrable: true
    add_foreign_key "forms", "form_items", column: "root_id", deferrable: true
    add_foreign_key "forms", "forms", column: "original_id", on_delete: :nullify, deferrable: true
    add_foreign_key "forms", "missions", deferrable: true
    add_foreign_key "media_objects", "answers", deferrable: true
    add_foreign_key "operations", "missions", deferrable: true
    add_foreign_key "operations", "users", column: "creator_id", deferrable: true
    add_foreign_key "option_nodes", "missions", deferrable: true
    add_foreign_key "option_nodes", "option_nodes", column: "original_id", on_delete: :nullify, deferrable: true
    add_foreign_key "option_nodes", "option_sets", deferrable: true
    add_foreign_key "option_nodes", "options", deferrable: true
    add_foreign_key "option_sets", "missions", deferrable: true
    add_foreign_key "option_sets", "option_nodes", column: "root_node_id", deferrable: true
    add_foreign_key "option_sets", "option_sets", column: "original_id", on_delete: :nullify, deferrable: true
    add_foreign_key "options", "missions", deferrable: true
    add_foreign_key "questions", "missions", deferrable: true
    add_foreign_key "questions", "option_sets", deferrable: true
    add_foreign_key "questions", "questions", column: "original_id", on_delete: :nullify, deferrable: true
    add_foreign_key "report_calculations", "questions", column: "question1_id", deferrable: true
    add_foreign_key "report_calculations", "report_reports", deferrable: true
    add_foreign_key "report_option_set_choices", "option_sets", deferrable: true
    add_foreign_key "report_option_set_choices", "report_reports", deferrable: true
    add_foreign_key "report_reports", "form_items", column: "disagg_qing_id", deferrable: true
    add_foreign_key "report_reports", "forms", deferrable: true
    add_foreign_key "report_reports", "missions", deferrable: true
    add_foreign_key "report_reports", "users", column: "creator_id", deferrable: true
    add_foreign_key "responses", "forms", deferrable: true
    add_foreign_key "responses", "missions", deferrable: true
    add_foreign_key "responses", "users", column: "checked_out_by_id", deferrable: true
    add_foreign_key "responses", "users", column: "reviewer_id", deferrable: true
    add_foreign_key "responses", "users", deferrable: true
    add_foreign_key "settings", "missions", deferrable: true
    add_foreign_key "skip_rules", "form_items", column: "dest_item_id", deferrable: true
    add_foreign_key "skip_rules", "form_items", column: "source_item_id", deferrable: true
    add_foreign_key "sms_messages", "broadcasts", deferrable: true
    add_foreign_key "sms_messages", "missions", deferrable: true
    add_foreign_key "sms_messages", "sms_messages", column: "reply_to_id", deferrable: true
    add_foreign_key "sms_messages", "users", deferrable: true
    add_foreign_key "taggings", "questions", deferrable: true
    add_foreign_key "taggings", "tags", deferrable: true
    add_foreign_key "tags", "missions", deferrable: true
    add_foreign_key "user_group_assignments", "user_groups", deferrable: true
    add_foreign_key "user_group_assignments", "users", deferrable: true
    add_foreign_key "user_groups", "missions", deferrable: true
    add_foreign_key "users", "missions", column: "last_mission_id", on_delete: :nullify, deferrable: true
    add_foreign_key "whitelistings", "users", deferrable: true
  end
  # rubocop:enable Metrics/LineLength, Metrics/AbcSize, Metrics/MethodLength
end
