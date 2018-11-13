# frozen_string_literal: true

# Iterates over the answers table and inserts the appropriate entries into the answer_hierarchies table.
class AddAnswerHierarchies < ActiveRecord::Migration[4.2]
  def up
    ActiveRecord::Migration.suppress_messages do
      puts("Disabling indices")
      remove_index("answer_hierarchies", name: "answer_anc_desc_idx")
      remove_index("answer_hierarchies", name: "answer_desc_idx")

      puts("Deleting existing hierarchies")
      execute("DELETE FROM answer_hierarchies")

      @inserts = []

      puts("Calculating hierarchies")
      add_for([])

      do_inserts

      puts("Re-enabling indices")
      add_index("answer_hierarchies", %w[ancestor_id descendant_id generations],
        name: "answer_anc_desc_idx", unique: true, using: :btree)
      add_index("answer_hierarchies", ["descendant_id"], name: "answer_desc_idx", using: :btree)
    end
  end

  private

  def add_for(ancestor_ids)
    answers = answers_by_parent_id[ancestor_ids.last]
    return if answers.blank?

    (ancestor_ids + [:self]).reverse.each_with_index do |aid, i|
      answers.each do |answer|
        aid_str = aid == :self ? answer["id"] : aid
        @inserts << "('#{aid_str}', '#{answer['id']}', #{i})"
      end
    end
    answers.each { |r| add_for(ancestor_ids + [r["id"]]) }
  end

  def answers_by_parent_id
    return @answers_by_parent_id if @answers_by_parent_id

    puts("Fetching all answers and grouping by parent_id")
    @answers_by_parent_id = execute("SELECT id, parent_id FROM answers WHERE deleted_at IS NULL")
      .to_a.group_by { |r| r["parent_id"] }
  end

  def do_inserts
    batched_insert("answer_hierarchies", "ancestor_id,descendant_id,generations", @inserts)
  end

  def batched_insert(tbl, cols, rows)
    puts("Inserting rows")
    puts("  Rows to be inserted: #{rows.size}")
    total_slices = (rows.size.to_f / 10_000).ceil
    rows.each_slice(10_000).with_index do |slice, i|
      puts("  Inserting slice #{i + 1}/#{total_slices}")
      execute("INSERT INTO #{tbl} (#{cols}) VALUES #{slice.join(',')}")
    end
  end
end
