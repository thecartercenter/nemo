class CopyMissionToJoinClasses < ActiveRecord::Migration
  def up
    # copy mission to newly added columns
    Questioning.all.each{|q| q.mission_id = q.question.mission_id; q.save(:validate => false)}
    Condition.all.each{|c| c.mission_id = c.questioning.mission_id; c.save(:validate => false)}
    Optioning.all.each{|o| o.mission_id = o.option_set.mission_id; o.save(:validate => false)}
  end

  def down
  end
end
