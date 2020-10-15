# frozen_string_literal: true

module ODK
  # This class is used to represent a fragment of a QingGroup.
  # ODK has issues showing a multilevel question inside a group,
  # so we split up a group that has a multilevel question on it
  # and remove it from the group to send it for ODK.
  #
  # Instances of this hold the other questions on the group that
  # weren't a multilevel question.
  #
  # See ODK::QingGroupPartitioner for more details.
  class QingGroupFragment
    include Translatable

    attr_accessor :children, :qing_group, :level

    delegate :disabled, :id, :group_name, :group_hint, :group_name_translations,
      :group_hint_translations, :repeatable, to: :qing_group

    def initialize(qing_group, children, level = nil)
      raise "QingGroup fragments must have at least one child" if children.blank?
      self.qing_group = qing_group
      self.children = children
      self.level = level
    end

    def fragment?
      true
    end

    def repeatable?
      false
    end

    def group_children?
      false
    end

    def multilevel_fragment?
      children.size == 1 && children.first.multilevel?
    end

    def one_screen?
      # Fragments don't get created unless the group is set to one_screen
      true
    end

    def sorted_children
      children # sorted when fragment created in partitioner
    end

    def childless?
      false
    end

    def root?
      false
    end

    def visible?
      enabled?
    end

    def enabled?
      true
    end
  end
end
