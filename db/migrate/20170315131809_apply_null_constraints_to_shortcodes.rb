class ApplyNullConstraintsToShortcodes < ActiveRecord::Migration
  def change
    change_column :missions, :shortcode, :string, null: false
    change_column :responses, :shortcode, :string, null: false
  end
end
