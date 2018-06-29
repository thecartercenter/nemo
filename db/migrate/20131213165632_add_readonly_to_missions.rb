class AddReadonlyToMissions < ActiveRecord::Migration[4.2]
  def change
    add_column :missions, :locked, :boolean, :null => false, :default => false
  end
end
