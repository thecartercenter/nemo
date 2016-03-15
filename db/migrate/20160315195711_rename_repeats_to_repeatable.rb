class RenameRepeatsToRepeatable < ActiveRecord::Migration
  def change
    rename_column :form_items, :repeats, :repeatable
  end
end
