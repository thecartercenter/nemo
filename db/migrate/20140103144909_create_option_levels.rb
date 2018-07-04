class CreateOptionLevels < ActiveRecord::Migration[4.2]
  def change
    create_table :option_levels do |t|
      t.integer :option_set_id, :null => false
      t.integer :rank, :null => false
      t.text :name_translations, :null => false
      t.integer :mission_id
      t.boolean :is_standard, :null => false, :default => false
      t.integer :standard_id

      t.timestamps
    end

    # only one standard copy per mission
    add_index :option_levels, [:mission_id, :standard_id], :unique => true

    # ranks must be unique per mission/option set pair
    add_index :option_levels, [:mission_id, :option_set_id, :rank], :unique => true

    add_foreign_key :option_levels, :option_sets
    add_foreign_key :option_levels, :option_levels, :column => :standard_id
  end
end
