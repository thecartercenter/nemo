class ChangeQuestioningsToFormItems < ActiveRecord::Migration[4.2]
  def change 
    rename_table :questionings, :form_items
    add_column :form_items, :type, :string
    add_column :form_items, :ancestry, :string
    add_column :form_items, :ancestry_depth, :integer
    add_column :form_items, :group_name_translations, :string

    add_column :forms, :root_id, :integer
  end
end
