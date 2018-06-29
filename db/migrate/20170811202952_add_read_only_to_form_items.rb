class AddReadOnlyToFormItems < ActiveRecord::Migration[4.2]
  def change
    add_column :form_items, :read_only, :boolean
  end
end
