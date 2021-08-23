# frozen_string_literal: true

module Results
  # Updates the search vector on the Answers model and provides the trigger query to do the same.
  #
  # After modifying, make sure you run `rake db:generate_trigger_migration`
  # (see https://github.com/jenseng/hair_trigger).
  class AnswerSearchVectorUpdater
    include Singleton

    # Efficiently updates the TSV for all answers referencing the given option node.
    def update_for_option_node(option_node)
      SqlRunner.instance.run("ALTER TABLE answers DISABLE TRIGGER answers_before_insert_update_row_tr")
      SqlRunner.instance.run(update_answers_with_matching_node_id, search_tokens(option_node), option_node.id)
      SqlRunner.instance.run(update_answers_with_choices, option_node.id)
      SqlRunner.instance.run("ALTER TABLE answers ENABLE TRIGGER answers_before_insert_update_row_tr")
    end

    # Builds the expression that evaluates to the appropriate TSV for a given answer.
    # Usually the table would be `answers` but in the case of a trigger expression it needs to be `new`.
    # This is not efficient when updating many rows but fine for a trigger which operates on a single row.
    def trigger_expression
      <<-SQL.squish
        TO_TSVECTOR('simple', COALESCE(
          new.value,
          to_char(new.date_value, 'YYYY-MM-DD'),
          to_char(new.time_value, 'HH24hMImSSs'),
          to_char(new.datetime_value, 'YYYY-MM-DD HH24hMImSSs'),
          (SELECT STRING_AGG(opt_name_translation.value, ' ')
            FROM options, option_nodes, JSONB_EACH_TEXT(options.name_translations) opt_name_translation
            WHERE
              options.id = option_nodes.option_id
              AND (option_nodes.id = new.option_node_id
                OR option_nodes.id IN (SELECT option_node_id FROM choices WHERE answer_id = new.id))),
          ''
        ))
      SQL
    end

    private

    def search_tokens(option_node)
      option_node.name_translations.values.reject(&:blank?).join(" ")
    end

    def update_answers_with_matching_node_id
      <<-SQL.squish
        UPDATE answers SET tsv = TO_TSVECTOR('simple', ?)
          WHERE answers.option_node_id = ?
      SQL
    end

    # We need to first build up a subquery of TSVs with the translations of all associated options,
    # then update by using a subquery-style update.
    def update_answers_with_choices
      <<-SQL.squish
        UPDATE answers SET tsv = subquery.tsv
          FROM (#{ids_and_tsvectors_for_matching_answers}) AS subquery
          WHERE answers.id = subquery.answer_id
      SQL
    end

    def ids_and_tsvectors_for_matching_answers
      <<-SQL.squish
        SELECT
          answers.id AS answer_id,
          TO_TSVECTOR('simple', STRING_AGG(opt_name_translation.value, ' ')) AS tsv
        FROM answers, choices, option_nodes, options,
          JSONB_EACH_TEXT(options.name_translations) opt_name_translation
        WHERE answers.id IN (#{answer_ids_with_option_node_as_choice})
          AND answers.id = choices.answer_id
          AND choices.option_node_id = option_nodes.id
          AND option_nodes.option_id = options.id
        GROUP BY answers.id
      SQL
    end

    def answer_ids_with_option_node_as_choice
      "SELECT answer_id FROM choices WHERE option_node_id = ?"
    end
  end
end
