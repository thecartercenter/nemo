# Separates a qing group that contains multilevel
# questionings into several groups. The idea here is to just remove the
# multilevel questioning from the group, since ODK doesn't show it correctly
# if it's a child of a group.
#
# Input:
#  QingGroup qgroup
#     with children: Qing1, Qing2, MultilevelQing, Qing3
# Output:
#  [ QingGroupFragment with children Qing1 and Qing2,
#    QingGroupFragment with child MultilevelQing,
#    QingGroupFragment with child Qing3
#   ]
# or nil if the group does not need partitioning.
#
# A group doesn't need to be partitioned if
# - It has only one question (in this case, if it's a multilevel question, it will get rendered
#   on separate screens)
# - It has any group children (in this case, we don't allow rendering the group on one screen)
# - It doesn't have any multilevel children
# - It is a QingGroupFragment (already meet the criteria above, by definition)
class QingGroupOdkPartitioner
  def fragment(group)
    return nil unless needs_partition?(group)
    split_group_as_necessary(group)
  end

  private

  def needs_partition?(group)
    !group.fragment? &&
      group.children.count > 1 &&
      group.sorted_children.none? { |child| child.is_a?(QingGroup) } &&
      group.children.any?(&:multilevel?)
  end

  def split_group_as_necessary(group)
    result = []
    temp_group_children = []
    group.sorted_children.each do |child|
      if child.multilevel?
        result << QingGroupFragment.new(group, temp_group_children)
        child.level_count.times do |i|
          result << QingGroupFragment.new(group, [child], i + 1)
        end
        temp_group_children = []
      else
        temp_group_children << child
      end
    end
    result << QingGroupFragment.new(group, temp_group_children) unless temp_group_children.empty?
    result
  end
end
