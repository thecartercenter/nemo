# This migration was auto-generated via `rake db:generate_trigger_migration'.
# While you can edit this file, any changes you make to the definitions here
# will be undone by the next auto-generated trigger migration.

class DropTriggerAnswers < ActiveRecord::Migration
  def up
    drop_trigger("answers_before_insert_update_row_tr", "answers", :generated => true)
  end

  def down
    create_trigger("answers_before_insert_update_row_tr", :generated => true, :compatibility => 1).
        on("answers").
        before(:insert, :update) do
      "new.tsv := to_tsvector('simple', coalesce(new.value, ''));"
    end
  end
end
