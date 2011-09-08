class RenamePlacesIncompleteToTemporary < ActiveRecord::Migration
  def self.up
    rename_column :places, :incomplete, :temporary
  end

  def self.down
    rename_column :places, :temporary, :incomplete
  end
end
