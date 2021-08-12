# frozen_string_literal: true

# This migration was auto-generated via `rake db:generate_trigger_migration'.
# While you can edit this file, any changes you make to the definitions here
# will be undone by the next auto-generated trigger migration.

class CreateTriggerAnswersInsertUpdate4 < ActiveRecord::Migration[6.1]
  def up
    drop_trigger("answers_before_insert_update_row_tr", "answers", generated: true)

    create_trigger("answers_before_insert_update_row_tr", generated: true, compatibility: 1)
      .on("answers")
      .before(:insert, :update) do
      "new.tsv := TO_TSVECTOR('simple', COALESCE( new.value, to_char(new.date_value, 'YYYY-MM-DD'), to_char(new.time_value, 'HH24hMImSSs'), to_char(new.datetime_value, 'YYYY-MM-DD HH24hMImSSs'), (SELECT STRING_AGG(opt_name_translation.value, ' ') FROM options, option_nodes, JSONB_EACH_TEXT(options.name_translations) opt_name_translation WHERE options.id = option_nodes.option_id AND (option_nodes.id = new.option_node_id OR option_nodes.id IN (SELECT option_node_id FROM choices WHERE answer_id = new.id))), '' ));"
    end

    update_legacy_answers
  end

  def update_legacy_answers
    puts "Updating legacy answers."
    answers_to_update = Answer.where("answers.date_value IS NOT NULL OR answers.time_value IS NOT NULL OR answers.datetime_value IS NOT NULL")
    puts "Found #{answers_to_update.count}..."

    SqlRunner.instance.run("ALTER TABLE answers DISABLE TRIGGER answers_before_insert_update_row_tr")
    SqlRunner.instance.run(update_answers_with_date)
    SqlRunner.instance.run("ALTER TABLE answers ENABLE TRIGGER answers_before_insert_update_row_tr")
  end

  # Simplified TSV copied from answer_search_vector_updater#trigger_expression.
  def update_answers_with_date
    <<-SQL.squish
        UPDATE answers SET tsv = TO_TSVECTOR('simple', COALESCE(
            answers.value,
            to_char(answers.date_value, 'YYYY-MM-DD'),
            to_char(answers.time_value, 'HH24hMImSSs'),
            to_char(answers.datetime_value, 'YYYY-MM-DD HH24hMImSSs')
          ))
          WHERE answers.date_value IS NOT NULL
          OR answers.time_value IS NOT NULL
          OR answers.datetime_value IS NOT NULL
    SQL
  end

  def down
    drop_trigger("answers_before_insert_update_row_tr", "answers", generated: true)

    create_trigger("answers_before_insert_update_row_tr", generated: true, compatibility: 1)
      .on("answers")
      .before(:insert, :update) do
      <<~SQL_ACTIONS
        new.tsv :=         TO_TSVECTOR('simple', COALESCE(
                  new.value,
                  (SELECT STRING_AGG(opt_name_translation.value, ' ')
                    FROM options, option_nodes, JSONB_EACH_TEXT(options.name_translations) opt_name_translation
                    WHERE
                      options.id = option_nodes.option_id
                      AND (option_nodes.id = new.option_node_id
                        OR option_nodes.id IN (SELECT option_node_id FROM choices WHERE answer_id = new.id))),
                  ''
                ))
        ;
      SQL_ACTIONS
    end
  end
end
