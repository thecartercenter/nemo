class AddAccessLevelToQuestion < ActiveRecord::Migration[4.2]
  def change
    add_column :questionables, :access_level, :tinyint  
  end
end
