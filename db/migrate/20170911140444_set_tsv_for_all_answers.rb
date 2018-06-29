class SetTsvForAllAnswers < ActiveRecord::Migration[4.2]
  def up
    # Forces trigger to run for all answers, setting up TSV stuff.
    execute("UPDATE answers SET id = id")
  end

  def down
  end
end
