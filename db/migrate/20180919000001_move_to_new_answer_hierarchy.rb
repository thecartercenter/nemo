# frozen_string_literal: true

require 'benchmark'

# Major migration to create hierarchy of answer objects.
class MoveToNewAnswerHierarchy < ActiveRecord::Migration[4.2]
  def up
    ActiveRecord::Migration.suppress_messages do
      @new_rows = {}
      @parent_rows = {}

      without_trigger do
        delete_leaf_nodes
        create_hierarchy_nodes
        fix_ranks
      end
    end
  end

  private

  def without_trigger
    execute("ALTER TABLE answers DISABLE TRIGGER answers_before_insert_update_row_tr")
    yield
    execute("ALTER TABLE answers ENABLE TRIGGER answers_before_insert_update_row_tr")
  end

  def delete_leaf_nodes
    # Delete all existing non-Answer-type rows, making this script idempotent, since it only
    # creates this type of rows.
    puts("Deleting any old non-leaf nodes")
    execute("DELETE FROM answers WHERE type != 'Answer'")
  end

  # Creates the nodes required to represent the new hierarchy system.
  def create_hierarchy_nodes
    # The basic idea here is, for each existing answer, to recursively find or create its parents
    # and then 1. set the parent_id on the row and 2. create the appropriate rows in the hierarchies table.
    # We do in batches of 10,000 so we can report progress.
    puts "Creating hierarchy nodes"
    puts "  Running main SELECT query"
    result = execute("SELECT id, response_id, questioning_id, inst_num, rank, type
      FROM answers WHERE deleted_at IS NULL")
    total_slices = (leaf_node_count.to_f / 10_000).ceil
    result.each_slice(10_000).with_index do |slice, i|
      @inserts = []
      @updates = []
      puts("  Processing slice #{i + 1}/#{total_slices}")
      run_and_print_time(2) do
        puts("    Building trees in memory")
        run_and_print_time(4) { slice.each { |row| find_or_create_parent_row(row) } }
        puts("    Inserting new ResponseNodes")
        run_and_print_time(4) { do_inserts }
        puts("    Updating existing Answers")
        run_and_print_time(4) { do_updates }
      end
    end
  end

  # Finds or creates the parent row for the given row.
  # Associates the given row with it.
  # If the given row is a top level node, then this amounts to finding/creating
  # the root node for the response.
  # Returns the ID of the found/created row.
  def find_or_create_parent_row(row, inst_num: nil)
    orig_row = row.dup

    form_item = form_items_by_id[row["questioning_id"]]

    raise "No FormItem found with ID #{row['questioning_id']}" if form_item.nil?

    # Terminate the recursion if we reach the root.
    if form_item["ancestry"].nil?
      row["new_rank"] = 0
      return nil
    end

    # If given row is an AnswerGroup that references a repeatable QingGroup, find/create AnswerGroupSet.
    if row["type"] == "AnswerGroup" && (form_item["repeatable"] == "t" || form_item["repeatable"] == true)
      parent_row = row.slice("questioning_id", "response_id")
        .merge("type" => "AnswerGroupSet", "inst_num" => 1)
      row["new_rank"] = inst_num
    # Else if it references a question with a multilevel option set, find/create AnswerSet.
    elsif row["type"] == "Answer" && form_item["level_names"].present?
      parent_row = row.slice("questioning_id", "inst_num", "response_id").merge("type" => "AnswerSet")
      row["new_rank"] = row["rank"]
    # Else just find/create its parent AnswerGroup.
    else
      parent_row = row.slice("inst_num", "response_id").merge(
        "type" => "AnswerGroup",
        "questioning_id" => form_item["ancestry"].split("/").last
      )
    end

    # We can set the new_rank on the row here since the recursion happens before the insertion.
    # Another way to do this would be to load the parent form_item in the previous call and set it there.
    row["new_rank"] ||= form_item["rank"]

    # Short circuit if we've seen this arg before.
    if (pid = @parent_rows[[orig_row, inst_num]])
      return pid
    end

    # Recursive call.
    parent_row["parent_id"] = find_or_create_parent_row(parent_row, inst_num: row["inst_num"])

    # Now that we have the parent's parent_id, we can do the find/insert.
    parent_id = find_or_insert_hash(parent_row)

    # Answer rows are preexisting so we need to update them with parent_id and rank instead of
    # setting them on creation.
    update_answer(row["id"], parent_id, row["new_rank"]) if row["type"] == "Answer"

    # Save in hash for faster lookup and return
    @parent_rows[[orig_row, inst_num]] = parent_id
  end

  def form_items_by_id
    @form_items_by_id ||= execute("SELECT fi.id, ancestry, ancestry_depth, repeatable, level_names, rank
      FROM form_items fi
      LEFT OUTER JOIN questions q ON fi.question_id = q.id
      LEFT OUTER JOIN option_sets os ON os.id = q.option_set_id")
      .to_a.index_by { |r| r["id"] }
  end

  def find_or_insert_hash(hash)
    unless (hash.keys - %w[questioning_id response_id type inst_num new_rank parent_id]).empty?
      raise "Invalid keys: #{hash.keys}"
    end

    if (found = @new_rows[hash])
      found
    else
      id = SecureRandom.uuid
      @new_rows[hash] = id
      insert_answer_parent(id, hash)
      id
    end
  end

  def update_answer(id, parent_id, new_rank)
    @updates << "('#{id}', #{id_str(parent_id)}, '#{new_rank}')"
  end

  def insert_answer_parent(id, hash)
    @inserts << "('#{id}','#{hash['questioning_id']}','#{hash['response_id']}','#{hash['type']}',"\
      "'#{hash['inst_num']}','#{hash['new_rank']}',#{id_str(hash['parent_id'])},NOW(),NOW())"
  end

  def id_str(val)
    val.nil? ? "NULL" : "'#{val}'"
  end

  def do_inserts
    batched_insert(
      "answers",
      "id,questioning_id,response_id,type,inst_num,new_rank,parent_id,created_at,updated_at",
      @inserts
    )
  end

  def do_updates
    ensure_empty_tmp_table
    batched_insert("ansupdates", "id,parent_id,new_rank", @updates)
    execute("UPDATE answers AS a SET parent_id = u.parent_id, new_rank = u.new_rank
      FROM ansupdates u WHERE a.id = u.id")
  end

  def batched_insert(tbl, cols, rows)
    rows.each_slice(1000) do |slice|
      execute("INSERT INTO #{tbl} (#{cols})
        VALUES #{slice.join(',')}")
    end
  end

  def fix_ranks
    puts("Fixing ranks")
    puts("  Non-leaf node count: #{non_leaf_node_count}")
    result = execute("SELECT id FROM answers WHERE type != 'Answer' AND deleted_at IS NULL")
    total_slices = (non_leaf_node_count.to_f / 1_000).ceil
    result.each_slice(1_000).with_index do |slice, i|
      puts("  Processing slice #{i + 1}/#{total_slices}")
      run_and_print_time(2) do
        slice.each { |row| execute(rank_fix_sql(row["id"])) }
      end
    end
  end

  def rank_fix_sql(parent_id)
    <<~SQL
      UPDATE answers
        SET new_rank = t.seq
        FROM (
          SELECT id, row_number() OVER(ORDER BY new_rank) - 1 AS seq
          FROM answers
          WHERE parent_id = '#{parent_id}' AND deleted_at IS NULL
        ) AS t
        WHERE answers.id = t.id AND answers.new_rank != t.seq;
    SQL
  end

  def leaf_node_count
    @leaf_node_count ||= execute("SELECT COUNT(*) FROM answers WHERE deleted_at IS NULL")
      .to_a.first["count"].to_i
  end

  def non_leaf_node_count
    @non_leaf_node_count ||= execute("SELECT COUNT(*) FROM answers WHERE type != "\
      "'Answer' AND deleted_at IS NULL").to_a.first["count"].to_i
  end

  def run_and_print_time(indent, &block)
    t = Benchmark.realtime(&block)
    puts("#{' ' * indent}Took #{format('%.3f', t)}s")
  end

  def ensure_empty_tmp_table
    unless @tmp_created
      execute("CREATE TEMPORARY TABLE ansupdates (id uuid primary key, parent_id uuid, new_rank integer)")
      @tmp_created = true
    end
    execute("TRUNCATE ansupdates")
  end
end
