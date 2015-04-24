class FixBlankAncestries < ActiveRecord::Migration
  def up
    execute("UPDATE form_items SET ancestry = NULL WHERE ancestry = ''")
    execute("UPDATE option_nodes SET ancestry = NULL WHERE ancestry = ''")
  end

  def down
  end
end
