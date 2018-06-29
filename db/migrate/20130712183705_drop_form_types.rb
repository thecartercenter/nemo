class DropFormTypes < ActiveRecord::Migration[4.2]
  def up
    drop_table :form_types
    remove_column :forms, :form_type_id
  end

  def down
  end
end
