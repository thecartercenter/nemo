class ApplyNullConstraintsToShortcodes < ActiveRecord::Migration[4.2]
  def change
    change_column :missions, :shortcode, :string, null: false
    change_column :responses, :shortcode, :string, null: false
  end
end
