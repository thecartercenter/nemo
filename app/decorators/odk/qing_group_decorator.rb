module Odk
  class QingGroupDecorator < FormItemDecorator
    delegate_all

    def sorted_children
      decorate_collection(object.sorted_children, context: context)
    end

    def render_as_grid?
      return @render_as_grid if defined?(@render_as_grid)
      items = sorted_children

      return false if items.size <= 1 || !one_screen?

      items.all? do |i|
        i.is_a?(Questioning) &&
          i.qtype_name == "select_one" &&
          i.option_set == items[0].option_set &&
          !i.multilevel?
      end
    end

    def bind_tag(xpath_prefix: "/data")
      tag(:bind, nodeset: xpath(xpath_prefix), relevant: relevance)
    end

    def note_bind_tag(xpath_prefix: "/data")
      tag(:bind, nodeset: xpath(xpath_prefix) << "/header", readonly: "true()",
                 type: "string", relevant: relevance)
    end

    # If any children have grid mode, then the first child is rendered twice:
    # once as a label row and once as a normal row.
    def grid_label_row(xpath_prefix:)
      return unless render_as_grid?
      sorted_children[0].input_tags(group: self, render_mode: :label_row, xpath_prefix: xpath_prefix)
    end

    def xpath(prefix = "/data")
      "#{prefix}/#{odk_code}"
    end

    # Duck type
    def code
      nil
    end

    # Whether this group should be shown on one screen. For this to happen:
    # - one_screen must be true
    # - group must not have any group children (nested)
    # - group must not have any questions with conditions referring to other questions in the group
    def one_screen_appropriate?
      one_screen? && one_screen_allowed?
    end

    def one_screen_allowed?
      !has_group_children? && !internal_conditions?
    end

    def multilevel_children?
      children.any?(&:multilevel?)
    end

    # Checks if there are any conditions in this group that refer to other questions in this group.
    def internal_conditions?
      children.each do |item|
        next unless item.display_conditionally?
        item.display_conditions.each do |condition|
          return true if condition.ref_qing.parent_id == id
        end
      end
      false
    end

    def no_hint?
      group_hint_translations.nil? || group_hint_translations.values.all?(&:blank?)
    end
  end
end
