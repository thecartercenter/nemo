class AddReadonlyToMissions < ActiveRecord::Migration
  def change
    add_column :missions, :locked, :boolean, :null => false, :default => false
  end
end
