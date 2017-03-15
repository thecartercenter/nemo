class AddShortcodeToResponses < ActiveRecord::Migration
  def change
    add_column :responses, :shortcode, :string
    add_index :responses, :shortcode, unique: true
  end
end
