# frozen_string_literal: true

# This migration was auto-generated via `rake db:generate_trigger_migration'.
# While you can edit this file, any changes you make to the definitions here
# will be undone by the next auto-generated trigger migration.

class CreateTriggerAnswersInsertUpdate3 < ActiveRecord::Migration[5.2]
  def up
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

  def down
    drop_trigger("answers_before_insert_update_row_tr", "answers", generated: true)

    create_trigger("answers_before_insert_update_row_tr", generated: true, compatibility: 1)
      .on("answers")
      .before(:insert, :update) do
      <<-SQL_ACTIONS
          IF NEW.type = 'Answer' THEN
            NEW.tsv := TO_TSVECTOR('simple', COALESCE(
              NEW.value,
              (SELECT STRING_AGG(opt_name_translation.value, ' ')
                FROM options, jsonb_each_text(options.name_translations) opt_name_translation
                WHERE options.id = NEW.option_id
                  OR options.id IN (SELECT option_id FROM choices WHERE answer_id = NEW.id)),
              ''
            ));
          END IF;
      SQL_ACTIONS
    end
  end
end
