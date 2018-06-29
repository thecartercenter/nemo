class RenameWhitelists < ActiveRecord::Migration[4.2]
  def change
    rename_table :whitelists, :whitelistings
  end
end
