class AddReadOnlyToFormItems < ActiveRecord::Migration
  def change
    add_column :form_items, :read_only, :boolean
  end
end
