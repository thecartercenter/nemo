class AddAccessLevelToForms < ActiveRecord::Migration
  def change
    add_column :forms, :access_level, :tinyint
  end
end
