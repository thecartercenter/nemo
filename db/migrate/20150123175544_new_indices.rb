class NewIndices < ActiveRecord::Migration[4.2]
  def up
    # Obviously important.
    add_index :option_nodes, :ancestry

    # For checking for matches on replication.
    add_index :options, [:canonical_name, :mission_id]
    add_index :tags, [:name, :mission_id]
  end

  def down
  end
end
