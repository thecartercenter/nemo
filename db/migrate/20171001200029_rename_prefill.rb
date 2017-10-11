class RenamePrefill < ActiveRecord::Migration
  def change
    rename_column :form_items, :prefill_pattern, :default
  end
end
