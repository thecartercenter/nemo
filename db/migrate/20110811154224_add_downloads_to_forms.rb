class AddDownloadsToForms < ActiveRecord::Migration
  def self.up
    add_column :forms, :downloads, :integer
  end

  def self.down
    remove_column :forms, :downloads
  end
end
