# frozen_string_literal: true

class PopulateNewOptionNodeIdColumns < ActiveRecord::Migration[5.2]
  # Disable transaction wrapper so that the update queries will be committed even if we
  # have to fail the transaction because some ended up nil.
  disable_ddl_transaction!

  FLAG_PATH = Rails.root.join("tmp/create_missing_option_nodes").freeze

  def up
    copy_option_id_to_option_node_id
    if (pairs = missing_pairs).any?
      merge_missing_pairs(pairs)
      if (pairs = missing_pairs).any?
        if File.exist?(FLAG_PATH)
          create_missing_nodes(pairs)
          copy_option_id_to_option_node_id
        else
          print_missing_pairs(pairs)
          raise Exception
        end
      end
    end
    assert_no_missing_pairs_or_non_matching_option_ids
  end

  private

  def copy_option_id_to_option_node_id
    # This trigger is slow and the search data doesn't need to be updated here.
    execute("ALTER TABLE answers DISABLE TRIGGER answers_before_insert_update_row_tr")
    puts "Copying for answers..."
    execute_partitioned(answer_update_query, "answers")
    puts "Copying for choices..."
    execute_partitioned(choice_update_query, "choices")
    execute("ALTER TABLE answers ENABLE TRIGGER answers_before_insert_update_row_tr")
  end

  def answer_update_query
    <<-SQL
      UPDATE answers SET option_node_id = option_nodes.id
        FROM option_nodes, questions, form_items
        WHERE __PARTITION__
          AND answers.option_id IS NOT NULL
          AND answers.option_node_id IS NULL
          AND answers.questioning_id = form_items.id
          AND form_items.question_id = questions.id
          AND questions.option_set_id = option_nodes.option_set_id
          AND option_nodes.option_id = answers.option_id
    SQL
  end

  def choice_update_query
    <<-SQL
      UPDATE choices SET option_node_id = option_nodes.id
        FROM answers, option_nodes, questions, form_items
        WHERE __PARTITION__
          AND choices.option_id IS NOT NULL
          AND choices.option_node_id IS NULL
          AND choices.answer_id = answers.id
          AND answers.questioning_id = form_items.id
          AND form_items.question_id = questions.id
          AND questions.option_set_id = option_nodes.option_set_id
          AND option_nodes.option_id = choices.option_id
    SQL
  end

  def execute_partitioned(query, table, parts = 100)
    per_part = 16**32 / parts
    max = 16**32 - 1
    (0...parts).to_a.each do |num|
      puts "Part #{num + 1}/#{parts}"
      lower = (num * per_part).to_s(16).rjust(32, "0")
      upper = (num == parts - 1 ? max : (num + 1) * per_part).to_s(16).rjust(32, "0")
      clause = "#{table}.id >= '#{lower}' AND #{table}.id < '#{upper}'"
      execute(query.sub("__PARTITION__", clause))
    end
  end

  def missing_pairs
    null_answers = Answer.where(option_node_id: nil).where.not(option_id: nil)
      .includes(form_item: :question)
    null_choices = Choice.where(option_node_id: nil).where.not(option_id: nil)
      .includes(answer: {form_item: :question})
    return [] if null_answers.none? && null_choices.none?

    pairs = null_answers.map { |a| [a.option_set_id, a.option_id] }
    pairs.concat(null_choices.map { |c| [c.answer.option_set_id, c.option_id] })
  end

  def merge_missing_pairs(pairs)
    puts "Attempting to merge missing pairs..."

    pairs.uniq.group_by { |p| p[0] }.each do |opt_set_id, subpairs|
      merge_missing_pairs_for_option_set(opt_set_id, subpairs)
    end
  end

  def merge_missing_pairs_for_option_set(opt_set_id, pairs)
    opt_set = OptionSet.find(opt_set_id)
    opt_ids = {}

    print_option_set_title(opt_set)

    # Index the existing options by hash.
    # TODO: Performance if huge?
    # TODO: Recurse for nested levels
    opt_set.first_level_options.map do |o|
      names = o.name_translations.map { |lang, name| [lang, name&.strip] }
      opt_ids[names.hash] = o.id
    end

    # See if any of the missing pairs have the same hash as an existing option.
    pairs.each do |pair|
      pair_opt_id = pair[1]
      names = Option.find(pair_opt_id).name_translations.map { |lang, name| [lang, name&.strip] }

      if (existing_opt_id = opt_ids[names.hash])
        puts "  Merging match for #{names} " \
          "(missing pair option #{pair_opt_id}, existing option #{existing_opt_id})"
        node = OptionNode.find_by(option_id: existing_opt_id)
        Answer.where(option_id: pair_opt_id).update_all(option_node_id: node.id, option_id: existing_opt_id)
        Choice.where(option_id: pair_opt_id).update_all(option_node_id: node.id, option_id: existing_opt_id)
      else
        puts "  Failed to find match for #{names} (option #{pair_opt_id})"
      end
    end
  end

  def print_missing_pairs(pairs)
    puts "Some answers/choices refer to options not contained in the expected option set:\n"

    pairs.uniq.group_by { |p| p[0] }.each do |opt_set_id, subpairs|
      print_missing_pairs_for_option_set(opt_set_id, subpairs)
    end

    puts "\nPlease fix them or run:"
    puts "    touch #{FLAG_PATH}"
    puts "and then run the migration again to have the migration"
    puts "add the missing options to the sets in question."
    puts "If the option set is not in active use, feel free to use the automated fix."
    puts "If the option set is in active use, consider the effects of adding new options to it."
    puts "You may prefer to manually delete the answers/choices in question."
  end

  def print_missing_pairs_for_option_set(opt_set_id, pairs)
    opt_set = OptionSet.find(opt_set_id)
    print_option_set_title(opt_set)
    puts "  Existing top-level options (up to 10):"
    puts opt_set.first_level_options[0...10].map { |o| "    #{o.name_translations}, (#{o.id})" }.join("\n")
    puts "  Options that were expected but not found:"
    pairs.each do |pair|
      option = Option.find(pair[1])
      puts "    #{option.name_translations}, (#{option.id})"
    end
  end

  def print_option_set_title(opt_set)
    puts "-----------------------------------------------------------------------------------------------"
    puts "Option Set: `#{opt_set.name}`, (#{opt_set.mission&.compact_name || 'admin'}, #{opt_set.id})"
  end

  def create_missing_nodes(pairs)
    puts "Creating missing option nodes..."
    pairs.each do |pair|
      rank = (OptionNode.where(ancestry_depth: 1, option_set_id: pair[0]).maximum(:rank) || 0) + 1
      sequence = (OptionNode.where(option_set_id: pair[0]).maximum(:sequence) || 0) + 1
      mission_id = Option.find(pair[1]).mission_id
      OptionNode.create!(option_set_id: pair[0], option_id: pair[1], mission_id: mission_id,
                         rank: rank, sequence: sequence)
    end
  end

  def assert_no_missing_pairs_or_non_matching_option_ids
    raise "Null pairs persist. Giving up." unless missing_pairs.none?
    non_match_query = <<-SQL
      SELECT COUNT(*) AS nonmatches FROM answers, option_nodes
        WHERE answers.option_node_id = option_nodes.id AND answers.option_id != option_nodes.option_id
    SQL
    return if execute(non_match_query).to_a[0]["nonmatches"].zero?
    raise "Some answers.option_id don't match option for answers.option_node_id, abort!"
  end
end
