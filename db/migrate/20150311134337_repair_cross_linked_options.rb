class RepairCrossLinkedOptions < ActiveRecord::Migration[4.2]
  def up
    # Fixes options which had gotten linked to missions outside their own via a suggestion system bug.

    ActiveRecord::Base.transaction do
      # First, make copies of the cross linked options.
      execute("INSERT INTO options (mission_id, created_at, updated_at, canonical_name, name_translations)
        SELECT ond.mission_id, o.created_at, o.updated_at, o.canonical_name, o.name_translations
        FROM option_nodes ond INNER JOIN options o ON ond.option_id = o.id
        WHERE o.mission_id != ond.mission_id
          /* This ensures there aren't already valid copies. */
          AND NOT EXISTS(
            select 1 from options o2 where o2.name_translations = o.name_translations and o2.mission_id = ond.mission_id)")

      # Now, relink the errant option nodes to the new copies.
      execute("UPDATE option_nodes ond INNER JOIN options o ON ond.option_id = o.id
        SET ond.option_id = (SELECT id FROM options o2 WHERE o2.mission_id = ond.mission_id
          AND o2.name_translations = o.name_translations LIMIT 1)
        WHERE o.mission_id != ond.mission_id")

      # Also, relink errant answers and choices to the new copies.
      execute("UPDATE answers a INNER JOIN responses r ON r.id = a.response_id INNER JOIN options o ON a.option_id = o.id
        SET a.option_id = (SELECT id FROM options o2 WHERE o2.mission_id = r.mission_id
          AND o2.name_translations = o.name_translations)
        WHERE o.mission_id != r.mission_id")
      execute("UPDATE choices c INNER JOIN answers a ON a.id = c.answer_id
          INNER JOIN responses r ON r.id = a.response_id INNER JOIN options o ON c.option_id = o.id
        SET c.option_id = (SELECT id FROM options o2 WHERE o2.mission_id = r.mission_id
          AND o2.name_translations = o.name_translations)
        WHERE o.mission_id != r.mission_id")

      # Also relink conditions, but this will only work if option_ids has only one id
      execute("UPDATE conditions c INNER JOIN options o ON c.option_ids = o.id
        SET c.option_ids = (SELECT id FROM options o2 WHERE o2.mission_id = c.mission_id
          AND o2.name_translations = o.name_translations)
        WHERE o.mission_id != c.mission_id")
    end
  end

  def down
  end
end
