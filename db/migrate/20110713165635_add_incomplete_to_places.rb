class AddIncompleteToPlaces < ActiveRecord::Migration[4.2]
  def self.up
    add_column :places, :is_incomplete, :boolean
  end

  def self.down
    remove_column :places, :is_incomplete
  end
end
