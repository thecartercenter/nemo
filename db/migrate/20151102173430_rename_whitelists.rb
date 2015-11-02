class RenameWhitelists < ActiveRecord::Migration
  def change
    rename_table :whitelists, :whitelistings
  end
end
