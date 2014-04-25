class AddAccessLevelToQuestion < ActiveRecord::Migration
  def change
    add_column :questionables, :access_level, :tinyint  
  end
end
