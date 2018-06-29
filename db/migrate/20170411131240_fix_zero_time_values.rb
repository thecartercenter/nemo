class FixZeroTimeValues < ActiveRecord::Migration[4.2]
  def up
    tables = %w(
      answers
      assignments
      broadcast_addressings
      broadcasts
      choices
      conditions
      delayed_jobs
      form_forwardings
      form_items
      form_versions
      forms
      media_objects
      missions
      operations
      option_nodes
      option_sets
      options
      questions
      report_calculations
      report_reports
      responses
      sessions
      settings
      sms_messages
      taggings
      tags
      user_group_assignments
      user_groups
      users
      whitelistings
    )

    tables.each do |table|
      execute("UPDATE #{table} SET created_at = '2000-01-01 00:00' WHERE created_at = '0000-00-00 00:00'")
      execute("UPDATE #{table} SET updated_at = '2000-01-01 00:00' WHERE updated_at = '0000-00-00 00:00'")
    end
  end
end
