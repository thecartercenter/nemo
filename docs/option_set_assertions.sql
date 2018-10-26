-- Execute these queries by pasting into PSQL console. All should return no rows.

-- Exactly one root OptionNode per option_set_id
SELECT option_set_id, COUNT(*)
  FROM option_nodes
  WHERE ancestry IS NULL AND deleted_at IS NULL
  GROUP BY option_set_id
  HAVING COUNT(*) > 1;

-- Contiguous rank
SELECT on1.id, on1.rank
  FROM option_nodes on1
  WHERE on1.rank > 1 AND on1.deleted_at IS NULL AND NOT EXISTS (
    SELECT id
      FROM option_nodes on2
      WHERE on2.deleted_at IS NULL AND on2.ancestry = on1.ancestry AND on2.rank = on1.rank - 1
  );

-- Non-duplicate ranks
SELECT ancestry, rank, COUNT(id)
  FROM option_nodes
  WHERE deleted_at IS NULL AND ancestry is NOT NULL
  GROUP BY ancestry, rank
  HAVING COUNT(id) > 1;

-- Roots have rank 1
SELECT id, rank
  FROM option_nodes
  WHERE rank != 1 AND ancestry IS NULL AND deleted_at IS NULL;

-- Non-roots have option IDs
SELECT ancestry FROM option_nodes WHERE option_id IS NULL AND deleted_at IS NULL AND rank > 1;

-- Conditions point to nodes in appropriate sets (not the end of the world if a few of
-- these don't line up, won't cause catastrophic failures).
SELECT id
  FROM conditions
  WHERE deleted_at IS NULL AND option_node_id IS NOT NULL
    AND (
      SELECT option_set_id
      FROM option_nodes
      WHERE id = option_node_id
    ) != (
      SELECT option_set_id
      FROM questions
      WHERE id IN (
        SELECT question_id FROM form_items WHERE id = conditions.ref_qing_id
      )
    );

-- Roots and Option Sets have same missions
SELECT id
  FROM option_sets
  WHERE deleted_at IS NULL AND mission_id != (
    SELECT mission_id
      FROM option_nodes
      WHERE option_set_id = option_sets.id AND ancestry IS NULL
  );

-- root_node_id agrees with node's option_set_id
SELECT id FROM option_sets WHERE deleted_at IS NULL AND root_node_id != (
  SELECT id
    FROM option_nodes
    WHERE option_set_id = option_sets.id AND ancestry IS NULL
);

-- Same as above but from other direction
SELECT id
  FROM option_nodes
  WHERE deleted_at IS NULL
    AND option_set_id != (SELECT id FROM option_sets WHERE deleted_at IS NULL AND root_node_id = id);
