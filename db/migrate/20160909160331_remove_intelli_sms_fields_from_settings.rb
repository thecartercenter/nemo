class RemoveIntelliSmsFieldsFromSettings < ActiveRecord::Migration
  def change
    remove_column :settings, :intellisms_password, :string
    remove_column :settings, :intellisms_username, :string
  end
end
