class RevampSettings < ActiveRecord::Migration[4.2]
  def up
    rename_column(:settings, :value, :timezone)
    remove_column(:settings, :key)
  end

  def down
  end
end
