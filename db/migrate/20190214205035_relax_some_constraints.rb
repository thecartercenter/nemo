# frozen_string_literal: true

class RelaxSomeConstraints < ActiveRecord::Migration[5.2]
  def change
    change_column_null :taggings, :tag_id, true
    change_column_comment :taggings, :tag_id, "Can't set null false due to replication process"

    change_column_null :sms_messages, :mission_id, true
    change_column_comment :sms_messages, :mission_id,
      "Can't set null false due to missionless SMS receive flow"

    change_column_null :broadcasts, :subject, true
    change_column_null :broadcasts, :body, false

    change_column_null :operations, :mission_id, true
    change_column_comment :operations, :mission_id, "Operations are possible in admin mode"
  end
end
