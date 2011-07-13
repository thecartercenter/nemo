class AddIncompleteToPlaces < ActiveRecord::Migration
  def self.up
    add_column :places, :is_incomplete, :boolean
  end

  def self.down
    remove_column :places, :is_incomplete
  end
end
