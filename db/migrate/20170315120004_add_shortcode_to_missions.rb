class AddShortcodeToMissions < ActiveRecord::Migration[4.2]
  def change
    add_column :missions, :shortcode, :string
    add_index :missions, :shortcode, unique: true
  end
end
