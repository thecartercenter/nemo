class AddShortcodeToMissions < ActiveRecord::Migration
  def change
    add_column :missions, :shortcode, :string
    add_index :missions, :shortcode, unique: true
  end
end
