class CopyMissionToJoinClasses < ActiveRecord::Migration[4.2]
  def up
    execute("UPDATE questionings qing SET qing.mission_id = (SELECT mission_id FROM questions q WHERE qing.question_id = q.id)")
    execute("UPDATE conditions c SET c.mission_id = (SELECT mission_id FROM questionings qing WHERE c.questioning_id = qing.id)")
    execute("UPDATE optionings o SET o.mission_id = (SELECT mission_id FROM option_sets os WHERE o.option_set_id = os.id)")
  end

  def down
  end
end
