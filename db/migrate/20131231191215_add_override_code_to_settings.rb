class AddOverrideCodeToSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :settings, :override_code, :string
  end

  def down
    remove_column :settings, :override_code
  end
end
