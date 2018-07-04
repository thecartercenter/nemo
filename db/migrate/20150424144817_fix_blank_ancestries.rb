class FixBlankAncestries < ActiveRecord::Migration[4.2]
  def up
    execute("UPDATE form_items SET ancestry = NULL WHERE ancestry = ''")
    execute("UPDATE option_nodes SET ancestry = NULL WHERE ancestry = ''")
  end

  def down
  end
end
