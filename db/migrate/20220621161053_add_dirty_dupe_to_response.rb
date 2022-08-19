# frozen_string_literal: true

class AddDirtyDupeToResponse < ActiveRecord::Migration[6.1]
  def up
    add_column :responses, :dirty_dupe, :boolean, default: true, null: false
    Response.update_all(dirty_dupe: false)
  end

  def down
    remove_column :responses, :dirty_dupe
  end
end
