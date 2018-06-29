class AddIndexInitialFormItemType < ActiveRecord::Migration[4.2]
  def up
    add_index :form_items, :ancestry
    FormItem.update_all(type: "Questioning")
  end

  def down 
  end
end
