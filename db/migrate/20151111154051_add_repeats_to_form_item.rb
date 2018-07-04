class AddRepeatsToFormItem < ActiveRecord::Migration[4.2]
  def change
    add_column :form_items, :repeats, :boolean
  end
end
