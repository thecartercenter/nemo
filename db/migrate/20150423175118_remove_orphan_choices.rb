class RemoveOrphanChoices < ActiveRecord::Migration[4.2]
  def up
    # Don't know where these came from, they're only an issue in staging data.
    execute("delete from choices where not exists (select 1 from answers where answers.id=choices.answer_id)")
  end

  def down
  end
end
