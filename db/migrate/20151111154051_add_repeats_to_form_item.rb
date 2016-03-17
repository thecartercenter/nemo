class AddRepeatsToFormItem < ActiveRecord::Migration
  def change
    add_column :form_items, :repeats, :boolean
  end
end
