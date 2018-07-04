# frozen_string_literal: true

class SetQuestioningIdResponseIdNullFalseOnAnswers < ActiveRecord::Migration[4.2]
  def up
    execute("UPDATE answers
      SET questioning_id = (SELECT id FROM form_items WHERE form_items.old_id = questioning_old_id)
      WHERE questioning_id IS NULL AND type = 'Answer'")
    execute("UPDATE answers
      SET response_id = (SELECT id FROM responses WHERE responses.old_id = response_old_id)
      WHERE response_id IS NULL AND type = 'Answer'")
    change_column_null :answers, :questioning_id, false
    change_column_null :answers, :response_id, false
  end
end
