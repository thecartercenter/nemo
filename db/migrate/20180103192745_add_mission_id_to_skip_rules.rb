class AddMissionIdToSkipRules < ActiveRecord::Migration[4.2]
  def change
    add_column :skip_rules, :mission_id, :uuid, index: true
    execute("UPDATE skip_rules SET mission_id =
      (SELECT mission_id FROM form_items WHERE form_items.id = skip_rules.source_item_id)")
  end
end
