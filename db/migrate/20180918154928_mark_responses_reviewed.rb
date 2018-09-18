# frozen_string_literal: true

class MarkResponsesReviewed < ActiveRecord::Migration[5.1]
  def up
    execute("UPDATE responses
      SET reviewed = true
      WHERE reviewer_id IS NOT NULL
      OR (reviewer_notes IS NOT NULL AND reviewer_notes != '')")
  end
end
