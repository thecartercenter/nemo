# frozen_string_literal: true

class CreateAuditLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :audit_logs, id: :uuid do |t|
      t.string :action, null: false
      t.string :resource, null: false
      t.uuid :resource_id
      t.jsonb :changes
      t.jsonb :metadata
      t.string :ip_address
      t.text :user_agent
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :mission, null: true, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_index :audit_logs, :user_id
    add_index :audit_logs, :mission_id
    add_index :audit_logs, :resource
    add_index :audit_logs, :resource_id
    add_index :audit_logs, :action
    add_index :audit_logs, :created_at
    add_index :audit_logs, [:user_id, :created_at]
    add_index :audit_logs, [:mission_id, :created_at]
    add_index :audit_logs, [:resource, :resource_id]
  end
end