class FormItemsNotNulls < ActiveRecord::Migration[4.2]
  def up
    execute('UPDATE form_items SET rank = 1 WHERE rank IS NULL')
    change_column :form_items, :form_id, :integer, null: false
    change_column :form_items, :rank, :integer, null: false
    change_column :form_items, :required, :boolean, null: false, default: false
    change_column :form_items, :hidden, :boolean, null: false, default: false
    change_column :form_items, :type, :string, null: false
    change_column :form_items, :ancestry_depth, :integer, null: false
  end

  def down
  end
end
