class RemoveUnassignedUsersFromWhitelist < ActiveRecord::Migration[4.2]
  def up
    execute <<-SQL
      DELETE wl
      FROM whitelists wl
        INNER JOIN forms f
          ON wl.whitelistable_type = 'Form' AND wl.whitelistable_id = f.id
        INNER JOIN missions m
          ON f.mission_id = m.id
      WHERE NOT EXISTS (
        SELECT 1
        FROM assignments a
        WHERE m.id = a.mission_id
        AND wl.user_id = a.user_id
      )
    SQL
  end
end
