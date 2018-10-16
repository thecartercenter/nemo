# frozen_string_literal: true

class RefactorOperationsToHaveMissionAndNewAttributes < ActiveRecord::Migration[5.1]
  def up
    execute("DELETE FROM operations")
    remove_column(:operations, :creator_old_id)
    remove_column(:operations, :old_id)
    rename_column(:operations, :description, :details)
    add_column(:operations, :mission_id, :uuid)
    add_column(:operations, :unread, :boolean, default: true, null: false)
    add_foreign_key(:operations, :missions)
    add_index(:operations, :mission_id)
  end

  # up and down instead of change because can't un-delete
  def down
    add_column(:operations, :creator_old_id, :integer)
    add_column(:operations, :old_id, :integer)
    rename_column(:operations, :details, :description)
    remove_column(:operations, :mission_id)
    remove_column(:operations, :unread)
  end
end
