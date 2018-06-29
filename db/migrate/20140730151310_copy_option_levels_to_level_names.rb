class CopyOptionLevelsToLevelNames < ActiveRecord::Migration[4.2]
  def up
    exec_query("SELECT option_set_id, CONCAT('[', GROUP_CONCAT(name_translations ORDER BY rank), ']') AS level_names
      FROM option_levels GROUP BY option_set_id;").each do |row|
        execute("UPDATE option_sets SET level_names='#{row['level_names']}' WHERE id=#{row['option_set_id']}")
    end
  end

  def down
  end
end
