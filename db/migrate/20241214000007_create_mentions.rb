# frozen_string_literal: true

class CreateMentions < ActiveRecord::Migration[8.0]
  def change
    create_table :mentions, id: :uuid do |t|
      t.references :comment, null: false, foreign_key: true, type: :uuid
      t.references :user, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_index :mentions, [:comment_id, :user_id], unique: true
  end
end