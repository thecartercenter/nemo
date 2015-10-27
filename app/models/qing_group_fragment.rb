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

  translates :group_name, :group_hint

  attr_accessor :hidden, :children

  def initialize(qing_group)
    @group_name_translations = qing_group.group_name_translations
    @group_hint_translations = qing_group.group_hint_translations
    @hidden = qing_group.hidden
    @children = ActiveSupport::OrderedHash.new
  end
end
