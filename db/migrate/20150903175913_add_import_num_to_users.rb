class AddImportNumToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :import_num, :integer
  end
end
