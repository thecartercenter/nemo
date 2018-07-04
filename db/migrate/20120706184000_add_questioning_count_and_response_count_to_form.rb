class AddQuestioningCountAndResponseCountToForm < ActiveRecord::Migration[4.2]
  def up
    add_column :forms, :questionings_count, :integer, :default => 0
    add_column :forms, :responses_count, :integer, :default => 0

    Form.reset_column_information
    execute("UPDATE forms f SET
      questionings_count = (SELECT COUNT(*) FROM questionings q WHERE q.form_id = f.id),
      responses_count = (SELECT COUNT(*) FROM responses r WHERE r.form_id = f.id)")
  end
  def down
    remove_column :forms, :questionings_count
    remove_column :forms, :responses_count
  end
end
