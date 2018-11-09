# frozen_string_literal: true

# This migration was auto-generated via `rake db:generate_trigger_migration'.
# While you can edit this file, any changes you make to the definitions here
# will be undone by the next auto-generated trigger migration.
class CreateTriggerAnswersInsertUpdate2 < ActiveRecord::Migration[4.2]
  def up
    drop_trigger("answers_before_insert_update_row_tr", "answers", generated: true)

    # Add a check for the row being Answer type. Other types don't need to be searched.
    create_trigger("answers_before_insert_update_row_tr", generated: true, compatibility: 1)
      .on("answers")
      .before(:insert, :update) do
        +<<-SQL
          IF NEW.type = 'Answer' THEN
            NEW.tsv := TO_TSVECTOR('simple', COALESCE(
              NEW.value,
              (SELECT STRING_AGG(opt_name_translation.value, ' ')
                FROM options, jsonb_each_text(options.name_translations) opt_name_translation
                WHERE options.id = NEW.option_id
                  OR options.id IN (SELECT option_id FROM choices WHERE answer_id = NEW.id)),
              ''
            ));
          END IF
        SQL
      end
  end

  def down
    drop_trigger("answers_before_insert_update_row_tr", "answers", generated: true)
  end
end
