# frozen_string_literal: true

# Update old form response counts
class CorrectFormResponsesCount < ActiveRecord::Migration[4.2]
  def up
    execute("UPDATE forms SET responses_count = (
      SELECT COUNT(*) FROM responses WHERE responses.form_id = forms.id AND responses.deleted_at IS NULL
    )")
  end

  def down
  end
end
