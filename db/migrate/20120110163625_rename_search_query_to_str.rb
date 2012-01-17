class RenameSearchQueryToStr < ActiveRecord::Migration
  def self.up
    change_column :searches, :query, :text
    rename_column :searches, :query, :str
  end

  def self.down
  end
end
