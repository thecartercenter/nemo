# frozen_string_literal: true

class AddStatusToForms < ActiveRecord::Migration[5.2]
  def change
    add_column :forms, :status, :string, null: false, default: "draft"
    add_index :forms, :status

    connection.execute("UPDATE forms SET status = 'live' WHERE published = 't'")
    connection.execute("UPDATE forms SET status = 'paused' WHERE published = 'f'
      AND current_version_id IS NOT NULL")
  end
end
