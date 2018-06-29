class RenameSearchesToSearchSearches < ActiveRecord::Migration[4.2]
  def self.up
    rename_table :searches, :search_searches
  end

  def self.down
    rename_table :search_searches, :searches
  end
end
