# frozen_string_literal: true

class CreateBackups < ActiveRecord::Migration[8.0]
  def change
    create_table :backups, id: :uuid do |t|
      t.string :backup_id, null: false
      t.string :backup_type, null: false
      t.string :file_path, null: false
      t.bigint :file_size, null: false
      t.boolean :include_media, default: false, null: false
      t.boolean :include_audit_logs, default: false, null: false
      t.string :status, default: "completed", null: false
      t.references :mission, null: false, foreign_key: true, type: :uuid
      t.references :user, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_index :backups, :backup_id, unique: true
    add_index :backups, :status
    add_index :backups, :created_at
  end
end
