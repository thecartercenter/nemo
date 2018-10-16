# frozen_string_literal: true

class DeleteDuplicateChoiceRowsAndAddUniqueIndex < ActiveRecord::Migration[5.1]
  def up
    result = execute("SELECT array_agg(id) FROM choices GROUP BY answer_id, option_id HAVING COUNT(*) > 1")
    result.each do |row|
      choice_ids = row["array_agg"][1...-1].split(",")
      raise "Should be more than 1 choice here!" if choice_ids.size <= 1
      extra_ids = choice_ids[1..-1].map { |id| "'#{id}'" }.join(",")
      execute("DELETE FROM choices WHERE id IN (#{extra_ids})")
    end
    add_index(:choices, %i[answer_id option_id], unique: true)
  end
end
