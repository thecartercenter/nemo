class AddPrefillPatternToFormItems < ActiveRecord::Migration
  def change
    add_column :form_items, :prefill_pattern, :string
  end
end
