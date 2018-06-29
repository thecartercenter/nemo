class AddThemeToSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :settings, :theme, :string, null: false, default: "nemo"
  end
end
