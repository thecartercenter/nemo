class AddOverrideCodeToSettings < ActiveRecord::Migration
  def change
    add_column :settings, :override_code, :string
  end

  def down
    remove_column :settings, :override_code
  end
end
