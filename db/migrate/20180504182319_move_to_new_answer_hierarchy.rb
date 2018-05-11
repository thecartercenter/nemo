# frozen_string_literal: true

# Major migration to create hierarchy of answer objects.
class MoveToNewAnswerHierarchy < ActiveRecord::Migration
  ANSWER_TBL_NAME = "answers"

  # Helpful assertions to be considered for migrated data (not currently implemented):
  # - Exactly one root AnswerGroup per response_id
  # - Exactly one AnswerGroup per non-repeat group and response_id
  # - Exactly one AnswerGroupSet per repeat group and response_id
  # - Old inst_num is the same for all Answers in an AnswerGroup
  # - Contiguous, non-duplicate, 1-based ranks per parent_id
  # - All answers with rank > 1 have AnswerSet parents

  def up
    # First delete all existing non-Answer-type rows, making this script idempotent, since it only
    # creates this type of rows.
    execute("DELETE FROM #{ANSWER_TBL_NAME} WHERE type != 'Answer'")

    @form_item_parents = {}

    # The basic idea here is, for each existing answer, to recursively find or create its parents
    # and then 1. set the parent_id on the row and 2. create the appropriate rows in the hierarchies table.
    total = execute("SELECT COUNT(*) FROM #{ANSWER_TBL_NAME}").to_a.first["count"].to_i
    count = 0

    result = execute("SELECT id, response_id, questioning_id, inst_num, rank, type
      FROM #{ANSWER_TBL_NAME}
      WHERE response_id = '77a70b5c-887d-4044-976b-173af8c93bc8'")

    result.each do |row|
      find_or_create_parent_row(row)
      count += 1
    end
  end

  private

  # Finds or creates the parent row for the given row.
  # Associates the given row with it.
  # If the given row is a top level node, then this amounts to finding/creating
  # the root node for the response.
  # Returns the ID of the found/created row.
  def find_or_create_parent_row(row, inst_num: nil)
    form_item = execute("SELECT ancestry, ancestry_depth, repeatable, level_names, rank FROM form_items fi
      LEFT OUTER JOIN questions q ON fi.question_id = q.id
      LEFT OUTER JOIN option_sets os ON os.id = q.option_set_id
      WHERE fi.id = '#{row['questioning_id']}'").to_a.first

    # Terminate the recursion if we reach the root.
    if form_item["ancestry"].nil?
      row["new_rank"] = 1
      return nil
    end

    # If given row is an AnswerGroup that references a repeatable QingGroup, find/create AnswerGroupSet.
    if row["type"] == "AnswerGroup" && form_item["repeatable"] == "t"
      parent_row = row.slice("questioning_id", "response_id").merge("type" => "AnswerGroupSet")
      row["new_rank"] = inst_num
    # Else if it references a question with a multilevel option set, find/create AnswerSet.
    elsif row["type"] == "Answer" && form_item["level_names"].present?
      parent_row = row.slice("questioning_id", "inst_num", "response_id").merge("type" => "AnswerSet")
    # Else just find/create its parent AnswerGroup.
    else
      qing_group_id = form_item["ancestry"].split("/").last
      parent_row = row.slice("inst_num", "response_id")
        .merge(
          "type" => "AnswerGroup",
          "questioning_id" => qing_group_id
        )
    end

    # We can set the new_rank on the row here since the recursion happens before the insertion.
    # Another way to do this would be to load the parent form_item in the previous call and set it there.
    row["new_rank"] ||= form_item["rank"]

    # Recursive call.
    parent_row["parent_id"] = find_or_create_parent_row(parent_row, inst_num: row["inst_num"])

    # Now that we have the parent's parent_id, we can do the find/insert.
    parent_id = find_or_insert_hash(parent_row)

    # Answer rows are preexisting so we need to update them with parent_id and rank instead of
    # setting them on creation.
    if row["type"] == "Answer"
      execute("UPDATE #{ANSWER_TBL_NAME} SET
        parent_id = '#{parent_id}', new_rank = #{row['new_rank']} WHERE id = '#{row['id']}'")
    end

    parent_id
  end

  def find_or_insert_hash(hash)
    where = hash.map { |k, v| v.nil? ? "#{k} IS NULL" : "#{k} = '#{v}'" }.join(" AND ")
    result = execute("SELECT id, parent_id FROM #{ANSWER_TBL_NAME} WHERE #{where}").to_a
    if result.any?
      result.first["id"]
    else
      hash.reject! { |_, v| v.nil? }
      keys = hash.keys.join(",")
      values = hash.values.map { |v| "'#{v}'" }.join(",")
      insert("INSERT INTO #{ANSWER_TBL_NAME}(#{keys}) VALUES (#{values})")
    end
  end
end
