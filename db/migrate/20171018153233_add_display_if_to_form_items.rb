class AddDisplayIfToFormItems < ActiveRecord::Migration[4.2]
  def up
    add_column :form_items, :display_if, :string, default: 'always', null: false
    execute("UPDATE form_items SET display_if = 'all_met' WHERE
      (SELECT COUNT(*) FROM conditions where questioning_id = form_items.id) > 0")
  end

  def down
    remove_column :form_items, :display_if
  end
end
