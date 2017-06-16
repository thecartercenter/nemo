# Class responsible to reorganize the questions
# It's main concern is to separate a qing group that contains multilevel
# questionings into several groups. The idea here is to just remove the
# multilevel questioning from the group, since ODK doesn't show it correctly
# if it's a child of a group.
#
# Input:
#  QingGroup qgroup
#     with children: Qing1, Qing2, MultilevelQing, Qing3
# Output:
#  [ QingGroupTransient with children Qing1 and Qing2,
#    QingGroupTransient with child MultilevelQing,
#    QingGroupTransient with child Qing3
#   ]
#
class QingGroupOdkPartitioner

  def fragment(qing_group)
    result = nil
    if qing_group.sorted_children.none? {|child| child.is_a?(QingGroup)} && qing_group.children.any? {|c| c.multilevel?} && qing_group.children.count > 1
      result = split_qing_group_as_necessary(qing_group)
    end
    result
  end

  private

  def split_qing_group_as_necessary(qing_group)
    result = Array.new
    temp_group_children = Array.new
    qing_group.sorted_children.each do |child|
      if child.multilevel?
        result.push(QingGroupFragment.new(qing_group, temp_group_children))
        result.push(QingGroupFragment.new(qing_group, [child]))
        temp_group_children = []
      else
        temp_group_children.push(child)
      end
    end
    result.push(QingGroupFragment.new(qing_group, temp_group_children)) unless temp_group_children.empty?
    result
  end
end
