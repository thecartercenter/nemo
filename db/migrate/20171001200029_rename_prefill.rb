class RenamePrefill < ActiveRecord::Migration[4.2]
  def change
    rename_column :form_items, :prefill_pattern, :default
  end
end
