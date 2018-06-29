class CreateSkipRules < ActiveRecord::Migration[4.2]
  def change
    create_table :skip_rules do |t|
      t.uuid :source_item_id, null: false
      t.string :destination, null: false
      t.uuid :dest_item_id
      t.string :skip_if, null: false
      t.integer :rank, null: false
      t.datetime :deleted_at

      t.timestamps null: false
    end

    add_index :skip_rules, :source_item_id
    add_index :skip_rules, :dest_item_id
    add_index :skip_rules, :deleted_at

    add_foreign_key :skip_rules, :form_items, column: "source_item_id"
    add_foreign_key :skip_rules, :form_items, column: "dest_item_id"
  end
end
