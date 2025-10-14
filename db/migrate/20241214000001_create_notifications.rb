# frozen_string_literal: true

class CreateNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :notifications, id: :uuid do |t|
      t.string :title, null: false
      t.text :message
      t.string :type, null: false
      t.boolean :read, default: false, null: false
      t.jsonb :data
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :mission, null: true, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_index :notifications, :user_id
    add_index :notifications, :mission_id
    add_index :notifications, :read
    add_index :notifications, :type
    add_index :notifications, :created_at
  end
end