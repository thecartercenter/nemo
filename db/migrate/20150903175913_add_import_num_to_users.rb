class AddImportNumToUsers < ActiveRecord::Migration
  def change
    add_column :users, :import_num, :integer
  end
end
