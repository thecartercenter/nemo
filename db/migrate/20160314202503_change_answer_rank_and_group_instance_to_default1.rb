class ChangeAnswerRankAndGroupInstanceToDefault1 < ActiveRecord::Migration[4.2]
  def up
    change_column_default :answers, :group_instance, 1
    change_column_default :answers, :rank, 1
    execute("UPDATE answers SET group_instance = 1 WHERE group_instance IS NULL")
    execute("UPDATE answers SET rank = 1 WHERE rank IS NULL")
    change_column_null :answers, :group_instance, false
    change_column_null :answers, :rank, false
  end
end
