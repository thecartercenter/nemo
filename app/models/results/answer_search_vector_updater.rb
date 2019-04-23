# frozen_string_literal: true

module Results
  # Updates the search vector on the Answers model and provides the trigger query to do the same.
  class AnswerSearchVectorUpdater
    include Singleton

    # Efficiently updates the TSV for all answers referencing the given option.
    def update_for_option(option)
      SqlRunner.instance.run("ALTER TABLE answers DISABLE TRIGGER answers_before_insert_update_row_tr")

      # Update answers with matching option_id (easy).
      names = option.name_translations.values.reject(&:blank?).join(" ")
      SqlRunner.instance.run("UPDATE answers SET tsv = TO_TSVECTOR('simple', ?) "\
        "WHERE answers.option_id = ?", names, option.id)

      # Update answers with a matching choice option_id (hard).
      SqlRunner.instance.run(update_answers_with_choices, option.id)

      SqlRunner.instance.run("ALTER TABLE answers ENABLE TRIGGER answers_before_insert_update_row_tr")
    end

    # Builds the expression that evaluates to the appropriate TSV for a given answer.
    # Usually the table would be `answers` but in the case of a trigger expression it needs to be `new`.
    # This is not efficient when updating many rows but fine for a trigger which operates on a single row.
    def trigger_expression
      <<-SQL
        TO_TSVECTOR('simple', COALESCE(
          new.value,
          (SELECT STRING_AGG(opt_name_translation.value, ' ')
            FROM options, JSONB_EACH_TEXT(options.name_translations) opt_name_translation
            WHERE options.id = new.option_id
              OR options.id IN (SELECT option_id FROM choices WHERE answer_id = new.id)),
          ''
        ))
      SQL
    end

    private

    # We need to first build up a subquery of TSVs with the translations of all associated options,
    # then update by using a subquery-style update.
    def update_answers_with_choices
      <<-SQL
        UPDATE answers SET tsv = subquery.tsv
          FROM (#{ids_and_tsvectors_for_matching_answers}) AS subquery
          WHERE answers.id = subquery.answer_id
      SQL
    end

    def ids_and_tsvectors_for_matching_answers
      <<-SQL
        SELECT
          answers.id AS answer_id,
          TO_TSVECTOR('simple', STRING_AGG(opt_name_translation.value, ' ')) AS tsv
        FROM answers, choices, options, JSONB_EACH_TEXT(options.name_translations) opt_name_translation
        WHERE answers.id = choices.answer_id AND choices.option_id = options.id
          AND answers.id IN (#{answer_ids_with_option_as_choice})
        GROUP BY answers.id
      SQL
    end

    def answer_ids_with_option_as_choice
      "SELECT answer_id FROM choices WHERE option_id = ?"
    end
  end
end
