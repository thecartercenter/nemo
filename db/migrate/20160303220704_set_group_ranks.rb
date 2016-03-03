class SetGroupRanks < ActiveRecord::Migration
  def up
    QingGroup.where("ancestry IS NOT NULL").all.each do |qg|
      FormItem.where(id: qg.children.pluck(:id)).update_all("group_rank = #{qg.rank}")
    end
  end
end
