# This class is used to represent a fragment of a QingGroup.
# ODK has issues showing a multilevel question inside a group,
# so we split up a group that has a multilevel question on it
# and remove it from the group to send it for ODK.
#
# Instances of this hold the other questions on the group that
# weren't a multilevel question.
#
# See QingGroupOdkPartitioner for more details.
class QingGroupFragment
  include Translatable

  attr_accessor :children, :qing_group

  delegate :hidden, :id, :group_name, :group_hint, :group_name_translations,
    :group_hint_translations, :repeatable, :odk_code, to: :qing_group

  def initialize(qing_group, children)
    self.qing_group = qing_group
    self.children = children
  end

  def multilevel?
    children.first.multilevel?
  end

  def childless?
    children.empty?
  end

  def sorted_children
    children # sorted when fragment created in partitioner
  end
end
