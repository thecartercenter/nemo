class ConvertSkipRuleToUuid < ActiveRecord::Migration[4.2]
  def up
    drop_table "skip_rules"

    create_table "skip_rules", id: :uuid, default: "uuid_generate_v4()", force: :cascade do |t|
      t.datetime "created_at", null: false
      t.datetime "deleted_at"
      t.uuid "dest_item_id"
      t.string "destination", null: false
      t.integer "rank", null: false
      t.string "skip_if", null: false
      t.uuid "source_item_id", null: false
      t.datetime "updated_at", null: false
    end

    add_index :skip_rules, :source_item_id
    add_index :skip_rules, :dest_item_id
    add_index :skip_rules, :deleted_at

    add_foreign_key :skip_rules, :form_items, column: "source_item_id"
    add_foreign_key :skip_rules, :form_items, column: "dest_item_id"
  end
end
