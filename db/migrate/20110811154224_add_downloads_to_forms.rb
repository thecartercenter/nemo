class AddDownloadsToForms < ActiveRecord::Migration[4.2]
  def self.up
    add_column :forms, :downloads, :integer
  end

  def self.down
    remove_column :forms, :downloads
  end
end
