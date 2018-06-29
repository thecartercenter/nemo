class RenameRepeatsToRepeatable < ActiveRecord::Migration[4.2]
  def change
    rename_column :form_items, :repeats, :repeatable
  end
end
