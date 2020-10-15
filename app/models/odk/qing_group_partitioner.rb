# frozen_string_literal: true

# Separates a qing group that contains multilevel questionings into several groups.
# The idea here is to just remove the multilevel questioning from the group and create a QingGroupFragment
# for each level of the multilevel questioning, since ODK doesn't show multilevel questions correctly
# if they're part of a one-screen group.
#
# Input:
#  QingGroup qgroup
#     with children: Qing1, Qing2, MultilevelQing, Qing3
# Output:
#  [ QingGroupFragment with children Qing1 and Qing2,
#    QingGroupFragment with child MultilevelQing, level 1
#    QingGroupFragment with child MultilevelQing, level 2
#    QingGroupFragment with child MultilevelQing, level 3
#    QingGroupFragment with child Qing3
#   ]
# or nil if the group does not need partitioning.
#
# A group doesn't need to be partitioned if
# - It's not a one-screen group
# - It has only one question (in this case, if it's a multilevel question, it will get rendered
#   on separate screens)
# - It has any group children (in this case, we don't allow rendering the group on one screen)
# - It doesn't have any multilevel children
# - It is a QingGroupFragment (already meet the criteria above, by definition)
module ODK
  class QingGroupPartitioner
    def fragment(group)
      return nil unless needs_partition?(group)
      split_group_as_necessary(group)
    end

    private

    def needs_partition?(group)
      !group.fragment? && group.one_screen? && group.children.count > 1 &&
        !group.group_children? && group.multilevel_children?
    end

    def split_group_as_necessary(group)
      result = []
      temp_group_children = []
      group.sorted_children.each do |child|
        if child.multilevel?
          result << QingGroupFragment.new(group, temp_group_children) unless temp_group_children.empty?
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
end
