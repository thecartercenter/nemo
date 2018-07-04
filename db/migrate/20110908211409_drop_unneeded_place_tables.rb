class DropUnneededPlaceTables < ActiveRecord::Migration[4.2]
  def self.up
    drop_table :place_lookups
    drop_table :place_suggs
    #drop_table :place_sugg_sets
  end

  def self.down
  end
end
