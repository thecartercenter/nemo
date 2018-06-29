class AddPrefillPatternToFormItems < ActiveRecord::Migration[4.2]
  def change
    add_column :form_items, :prefill_pattern, :string
  end
end
