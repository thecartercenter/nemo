class AddUuidFieldsToTables < ActiveRecord::Migration[4.2]
  TABLES_FOR_MIGRATION = [:answers, :assignments, :broadcast_addressings, :broadcasts, :choices, :conditions,
    :form_forwardings, :form_items, :form_versions, :forms, :media_objects, :missions, :operations,
    :option_nodes, :option_sets, :options, :questions, :report_calculations, :report_option_set_choices,
    :report_reports, :responses, :settings, :sms_messages, :taggings, :tags,
    :user_group_assignments, :user_groups, :users, :whitelistings]

  def change
    TABLES_FOR_MIGRATION.each do |table_name|
      add_column table_name, :uuid, :string
      add_index table_name, :uuid
    end
  end
end
