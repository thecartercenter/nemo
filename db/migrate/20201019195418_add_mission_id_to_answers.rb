# frozen_string_literal: true

class AddMissionIdToAnswers < ActiveRecord::Migration[5.2]
  def up
    execute("ALTER TABLE answers DISABLE TRIGGER answers_before_insert_update_row_tr")
    add_column(:answers, :mission_id, :uuid)
    query = <<-SQL
      UPDATE answers
        SET mission_id = responses.mission_id
        FROM responses
        WHERE responses.id = answers.response_id
    SQL
    execute(query)
    add_index(:answers, :mission_id)
    add_foreign_key(:answers, :missions)
    change_column_null(:answers, :mission_id, false)
    execute("ALTER TABLE answers ENABLE TRIGGER answers_before_insert_update_row_tr")
  end
end
