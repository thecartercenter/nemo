class AddIndexInitialFormItemType < ActiveRecord::Migration
  def up
    add_index :form_items, :ancestry
    FormItem.update_all(type: "Questioning")
  end

  def down 
  end
end
