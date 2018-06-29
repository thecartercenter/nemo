class AddUniqueIndexToAnswersAndRemoveDuplicates < ActiveRecord::Migration[4.2]
  def change
    ids = execute("SELECT GROUP_CONCAT(id) FROM answers
      GROUP BY response_id, questioning_id, rank HAVING COUNT(*) > 1").to_a
    if ids.any?
      ids = ids.map{ |arr| arr[0].split(",")[1..-1] }.flatten.join(",")
      execute("DELETE FROM choices WHERE answer_id IN (#{ids})")
      execute("DELETE FROM answers WHERE id IN (#{ids})")
    end
    add_index :answers, [:response_id, :questioning_id, :rank]
  end
end
