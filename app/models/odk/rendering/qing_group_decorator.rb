module Odk
  module Rendering
    class QingGroupDecorator < SimpleDelegator
      def odk_code
        @odk_code ||= "grp#{id}"
      end

      # Whether this group should be shown on one screen. For this to happen:
      # - one_screen must be true
      # - group must not have any group children (nested)
      # - group must not have any questions with conditions referring to other questions in the group
      def one_screen_appropriate?
        one_screen? && !group_children? && !internal_conditions?
      end

      def fragment?
        false # is QingGroup, so isn't a fragment
      end

      def multilevel_fragment?
        false # is QingGroup, so isn't a fragment
      end

      def multilevel_children?
        children.any?(&:multilevel?)
      end

      # Checks if there are any conditions in this group that refer to other questions in this group.
      def internal_conditions?
        children.each do |item|
          next unless item.condition.present?
          return true if item.condition.ref_qing.parent_id == id
        end
        false
      end

      def no_hint?
        group_hint_translations.nil? || group_hint_translations.values.all?(&:blank?)
      end
    end
  end
end
