# frozen_string_literal: true

module Results
  # Updates the search vector on the Answers model and provides the trigger query to do the same.
  class AnswerSearchVectorUpdater
    include Singleton

    # Efficiently updates the TSV for all answers referencing the given option.
    def update_for_option(option)
      SqlRunner.instance.run("ALTER TABLE answers DISABLE TRIGGER answers_before_insert_update_row_tr")
      SqlRunner.instance.run("UPDATE answers "\
        "SET tsv = #{vector_expression} "\
        "WHERE option_id = ? "\
          "OR ? IN (SELECT option_id FROM choices WHERE answer_id = answers.id)", option.id, option.id)
      SqlRunner.instance.run("ALTER TABLE answers ENABLE TRIGGER answers_before_insert_update_row_tr")
    end

    # Builds the expression that evaluates to the appropriate TSV for <tblref>.
    # Usually this would be answers but in the case of a trigger expression it needs to be `new`,
    # so we make it a parameter.
    def vector_expression(tblref: "answers")
      "TO_TSVECTOR('simple', COALESCE(
        #{tblref}.value,
        (SELECT STRING_AGG(opt_name_translation.value, ' ')
          FROM options, jsonb_each_text(options.name_translations) opt_name_translation
          WHERE options.id = #{tblref}.option_id
            OR options.id IN (SELECT option_id FROM choices WHERE answer_id = #{tblref}.id)),
        ''
      ))"
    end
  end
end
