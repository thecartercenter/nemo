class AddDeletedAtToUniqueIndices < ActiveRecord::Migration[4.2]
  def up
    remove_index "answers", name: "answers_full"
    remove_index "form_forwardings", name: "form_forwardings_full"
    remove_index "form_versions", name: "index_form_versions_on_code"
    remove_index "missions", name: "index_missions_on_shortcode"
    remove_index "questions", name: "index_questions_on_mission_id_and_code"
    remove_index "responses", name: "index_responses_on_form_id_and_odk_hash"
    remove_index "responses", name: "index_responses_on_shortcode"
    remove_index "user_group_assignments", name: "index_user_group_assignments_on_user_id_and_user_group_id"
    remove_index "user_groups", name: "index_user_groups_on_name_and_mission_id"
    remove_index "users", name: "index_users_on_login"
    remove_index "users", name: "index_users_on_sms_auth_code"

    add_index "answers", %w(response_id questioning_id inst_num rank deleted_at),
      name: "answers_full", unique: true
    add_index "form_versions", ["code", "deleted_at"],
      name: "index_form_versions_on_code", unique: true
    add_index "missions", ["shortcode", "deleted_at"],
      name: "index_missions_on_shortcode", unique: true
    add_index "questions", ["mission_id", "code", "deleted_at"],
      name: "index_questions_on_mission_id_and_code", unique: true
    add_index "responses", ["form_id", "odk_hash", "deleted_at"],
      name: "index_responses_on_form_id_and_odk_hash", unique: true
    add_index "responses", ["shortcode", "deleted_at"],
      name: "index_responses_on_shortcode", unique: true
    add_index "user_group_assignments", ["user_id", "user_group_id", "deleted_at"],
      name: "index_user_group_assignments_on_user_id_and_user_group_id", unique: true
    add_index "user_groups", ["name", "mission_id", "deleted_at"],
      name: "index_user_groups_on_name_and_mission_id", unique: true
    add_index "users", ["login", "deleted_at"],
      name: "index_users_on_login", unique: true
    add_index "users", ["sms_auth_code", "deleted_at"],
      name: "index_users_on_sms_auth_code", unique: true
  end
end
