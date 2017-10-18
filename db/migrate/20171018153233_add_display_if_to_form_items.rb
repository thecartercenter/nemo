class AddDisplayIfToFormItems < ActiveRecord::Migration
  def change
    add_column :form_items, :display_if, :string, default: 'always', null: false
    execute("UPDATE form_items SET display_if = 'all_met' WHERE
      (SELECT COUNT(*) FROM conditions where questioning_id = form_items.id) > 0")
  end
end
