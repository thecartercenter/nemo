class AddOneScreenToFormItems < ActiveRecord::Migration
  def change
    add_column :form_items, :one_screen, :boolean
    execute("UPDATE form_items SET one_screen = 't' WHERE type = 'QingGroup'")
  end
end
