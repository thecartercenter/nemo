class RenamePlacesIncompleteToTemporary < ActiveRecord::Migration[4.2]
  def self.up
    rename_column :places, :incomplete, :temporary
  end

  def self.down
    rename_column :places, :temporary, :incomplete
  end
end
