-- Execute these queries by pasting into PSQL console. All should return no rows.

-- Exactly one root AnswerGroup per response_id
select response_id, count(*)
  from answers
  where parent_id is null and deleted_at is null
  group by response_id
  having count(*) > 1;

-- Exactly one AnswerGroup per non-repeat group and response_id
select response_id, questioning_id, count(a.id)
  from answers a inner join form_items f on f.id = a.questioning_id
  where a.type = 'AnswerGroup' and f.repeatable = 'f'
  group by questioning_id, response_id
  having count(a.id) > 1;

-- Exactly one AnswerGroupSet per repeat group and response_id
select response_id, questioning_id, count(a.id)
  from answers a inner join form_items f on f.id = a.questioning_id
  where a.type = 'AnswerGroupSet' and f.repeatable = 't'
  group by questioning_id, response_id
  having count(a.id) > 1;

-- Contiguous new_rank
SELECT a1.id, a1.new_rank
  FROM answers a1
  WHERE a1.new_rank > 0 AND a1.deleted_at IS NULL AND NOT EXISTS (
    SELECT id
      FROM answers a2
      WHERE a2.deleted_at IS NULL AND a2.parent_id = a1.parent_id AND a2.new_rank = a1.new_rank - 1
  );

-- Non-duplicate ranks
SELECT parent_id, new_rank, COUNT(id)
  FROM answers
  WHERE deleted_at IS NULL AND parent_id is NOT NULL
  GROUP BY parent_id, new_rank
  HAVING COUNT(id) > 1;

-- Roots have new_rank 0.
SELECT a1.id, a1.new_rank
  FROM answers a1
  WHERE a1.new_rank != 0 AND a1.parent_id IS NULL AND a1.deleted_at IS NULL;

-- Old inst_num is the same for all Answers in an AnswerGroup
SELECT parent_id, COUNT(DISTINCT inst_num)
  FROM answers
  WHERE answers.deleted_at IS NULL AND answers.type = 'Answer'
  GROUP BY parent_id
  HAVING COUNT(DISTINCT inst_num) > 1;

-- Answers with old_rank > 1 should have AnswerSet as parent
SELECT answers.id
  FROM answers INNER JOIN answers parents ON answers.parent_id = parents.id
  WHERE answers.old_rank IS NOT NULL
    AND answers.deleted_at IS NULL
    AND answers.old_rank > 1
    AND parents.type != 'AnswerSet';

-- All Answer, AnswerSet, AnswerGroupSet have parent_id
SELECT id
  FROM answers
  WHERE deleted_at IS NULL AND type != 'AnswerGroup' AND parent_id IS NULL;

-- Answers never have children
SELECT answers.id
  FROM answers
  WHERE answers.deleted_at IS NULL AND type = 'Answer'
    AND EXISTS (SELECT children.id FROM answers children WHERE children.parent_id = answers.id);
