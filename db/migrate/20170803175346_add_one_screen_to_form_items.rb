class AddOneScreenToFormItems < ActiveRecord::Migration[4.2]
  def change
    add_column :form_items, :one_screen, :boolean
    execute("UPDATE form_items SET one_screen = 't' WHERE type = 'QingGroup'")
  end
end
