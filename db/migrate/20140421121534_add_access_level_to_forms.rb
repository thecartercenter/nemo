class AddAccessLevelToForms < ActiveRecord::Migration[4.2]
  def change
    add_column :forms, :access_level, :tinyint
  end
end
