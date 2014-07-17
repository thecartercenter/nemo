class CreateOptionNodes < ActiveRecord::Migration
  def change
    create_table :option_nodes do |t|
      t.string :ancestry
      t.integer :option_set_id, :null => false
      t.integer :option_id
      t.integer :rank, :null => false

      t.timestamps
    end

    add_foreign_key 'option_nodes', 'option_sets'
    add_foreign_key 'option_nodes', 'options'
    add_index 'option_nodes', ['rank']
  end
end
