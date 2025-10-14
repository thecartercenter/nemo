class NewIndices < ActiveRecord::Migration[4.2]
  def up
    # Obviously important.
    add_index :option_nodes, :ancestry

    # For checking for matches on replication.
    add_index :options, %i[canonical_name mission_id]
    add_index :tags, %i[name mission_id]
  end

  def down
  end
end
