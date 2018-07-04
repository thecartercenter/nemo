class RenameSearchQueryToStr < ActiveRecord::Migration[4.2]
  def self.up
    change_column :search_searches, :query, :text
    rename_column :search_searches, :query, :str
  end

  def self.down
  end
end
