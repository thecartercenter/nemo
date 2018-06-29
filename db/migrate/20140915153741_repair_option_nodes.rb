class RepairOptionNodes < ActiveRecord::Migration[4.2]
  def up
    # Delete any option nodes that have invalid ancestries.
    execute("delete c from option_nodes c left outer join option_nodes p on p.id = substring_index(c.ancestry, '/', 1)
      where c.ancestry is not null and p.id is null")

    # Fix missing option_set_ids by copying from root node.
    execute("update option_nodes c inner join option_nodes p on substring_index(c.ancestry, '/', 1) = p.id and c.option_set_id is null
      set c.option_set_id = p.option_set_id")
  end

  def down
  end
end
