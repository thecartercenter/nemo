class RemoveIntelliSmsFieldsFromSettings < ActiveRecord::Migration[4.2]
  def change
    remove_column :settings, :intellisms_password, :string
    remove_column :settings, :intellisms_username, :string
  end
end
