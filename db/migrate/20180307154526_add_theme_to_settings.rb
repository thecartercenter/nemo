class AddThemeToSettings < ActiveRecord::Migration
  def change
    add_column :settings, :theme, :string, null: false, default: "nemo"
  end
end
