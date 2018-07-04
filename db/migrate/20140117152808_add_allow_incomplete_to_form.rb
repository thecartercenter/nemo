class AddAllowIncompleteToForm < ActiveRecord::Migration[4.2]
  def change
    add_column :forms, :allow_incomplete, :boolean, :default => false, :null => false
  end

  def down
    remove_column :forms, :allow_incomplete
  end
end
