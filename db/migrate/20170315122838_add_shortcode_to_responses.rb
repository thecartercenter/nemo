class AddShortcodeToResponses < ActiveRecord::Migration[4.2]
  def change
    add_column :responses, :shortcode, :string
    add_index :responses, :shortcode, unique: true
  end
end
