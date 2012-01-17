class RenameSearchesToSearchSearches < ActiveRecord::Migration
  def self.up
    rename_table :searches, :search_searches
  end

  def self.down
    rename_table :search_searches, :searches
  end
end
