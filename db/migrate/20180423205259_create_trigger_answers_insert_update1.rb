# frozen_string_literal: true

# This migration was auto-generated via `rake db:generate_trigger_migration'.
# While you can edit this file, any changes you make to the definitions here
# will be undone by the next auto-generated trigger migration.
class CreateTriggerAnswersInsertUpdate1 < ActiveRecord::Migration[4.2]
  def up
    drop_trigger("answers_before_insert_update_row_tr", "answers", generated: true)

    create_trigger("answers_before_insert_update_row_tr", generated: true, compatibility: 1)
      .on("answers")
      .before(:insert, :update) do
      "new.tsv := TO_TSVECTOR('simple', COALESCE(
        new.value,
        (SELECT STRING_AGG(opt_name_translation.value, ' ')
          FROM options, jsonb_each_text(options.name_translations) opt_name_translation
          WHERE options.id = new.option_id
            OR options.id IN (SELECT option_id FROM choices WHERE answer_id = new.id)),
        ''
      ));"
    end

    # Force trigger to run for all rows.
    execute("UPDATE answers SET id = id")
  end

  def down
    drop_trigger("answers_before_insert_update_row_tr", "answers", generated: true)

    create_trigger("answers_before_insert_update_row_tr", generated: true, compatibility: 1)
      .on("answers")
      .before(:insert, :update) do
      "new.tsv := to_tsvector('simple', coalesce(new.value, ''));"
    end
  end
end
