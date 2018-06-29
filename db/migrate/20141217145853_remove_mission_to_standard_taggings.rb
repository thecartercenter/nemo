class RemoveMissionToStandardTaggings < ActiveRecord::Migration[4.2]
  def up
    # Taggings should no longer span from mission to standards
    execute("delete tg from taggings tg inner join tags t on tg.tag_id = t.id inner join questions q on tg.question_id = q.id
      where q.mission_id != t.mission_id")
  end

  def down
  end
end
