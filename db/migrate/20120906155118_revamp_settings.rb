class RevampSettings < ActiveRecord::Migration
  def up
    rename_column(:settings, :value, :timezone)
    remove_column(:settings, :key)
  end

  def down
  end
end
