# frozen_string_literal: true

class RemoveCachedGeoDataForSelectMultipleAnswers < ActiveRecord::Migration[5.2]
  def up
    # We are removing this feature so want to be backwards-consistent
    execute("UPDATE answers SET latitude = NULL, longitude = NULL WHERE id IN (
      SELECT a.id FROM answers a INNER JOIN form_items f ON a.questioning_id = f.id
        INNER JOIN questions q ON f.question_id = q.id
        WHERE a.latitude IS NOT NULL AND q.qtype_name = 'select_multiple')")
  end
end
