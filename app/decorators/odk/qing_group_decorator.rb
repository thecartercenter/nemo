# frozen_string_literal: true

module Odk
  # Decorates a QingGroup OR a QingGroupFragment for ODK purposes.
  class QingGroupDecorator < FormItemDecorator
    delegate_all

    def renderable_children
      @renderable_children ||=
        decorate_collection(object.sorted_children, context: context).select(&:renderable?)
    end

    def render_as_grid?
      return @render_as_grid if defined?(@render_as_grid)
      return (@render_as_grid = false) if root?
      return (@render_as_grid = false) if renderable_children.size <= 1 || !one_screen?
      @render_as_grid = renderable_children.all? do |item|
        item.grid_renderable?(option_set: renderable_children[0].option_set)
      end
    end

    def bind_tag(xpath_prefix: "/data")
      return +"" if root?
      tag(:bind, nodeset: xpath(xpath_prefix), relevant: relevance)
    end

    def note_bind_tag(xpath_prefix: "/data")
      return +"" if root?
      tag(:bind, nodeset: "#{xpath(xpath_prefix)}/header", readonly: "true()",
                 type: "string", relevant: relevance)
    end

    # The general structure for a group is:
    # group tag
    #   label
    #   repeat (if repeatable group)
    #     body
    #
    # The general structure for a fragment is:
    # group tag with field-list
    #   hint
    #   questions
    def body_tags(xpath_prefix:, **_options)
      return main_body_tags(xpath_prefix) if root?

      xpath = "#{xpath_prefix}/#{odk_code}"
      body_wrapper_tag(xpath) do
        if (fragments = Odk::QingGroupPartitioner.new.fragment(self))
          fragments = Odk::DecoratorFactory.decorate_collection(fragments)
          fragments.map { |f| f.body_tags(xpath_prefix: xpath_prefix) }.reduce(:<<)
        else
          inner_group_tag do
            # We include the hint here.
            # In the case of fragments, this means we include hint each time, which is correct.
            # This covers the case where self is a fragment, because fragments should always
            # be shown on one screen since that's what they're for.
            safe_str << group_item_name_tag << group_hint_tag(xpath) << main_body_tags(xpath)
          end
        end
      end
    end

    def xpath(prefix = "/data")
      [prefix, odk_code].compact.join("/")
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
      !group_children? && !internal_conditions?
    end

    def multilevel_children?
      children.any?(&:multilevel?)
    end

    def renderable?
      visible?
    end

    private

    def no_hint?
      group_hint_translations.nil? || group_hint_translations.values.all?(&:blank?)
    end

    # Checks if there are any conditions in this group that refer to other questions in this group.
    def internal_conditions?
      children.each do |item|
        next unless item.display_conditionally?
        item.display_conditions.each do |condition|
          return true if condition.left_qing.parent_id == id
        end
      end
      false
    end

    def body_wrapper_tag(xpath, &block)
      if fragment?
        # Fragments need no outer wrapper, they will get wrapped by field-list further in.
        yield
      else
        # Groups should get wrapped in a group tag and include the label.
        # Also a repeat tag if the group is repeatable
        content_tag(:group, ref: xpath) do
          tag(:label, ref: "jr:itext('#{odk_code}:label')") <<
            conditional_tag(:repeat, repeatable?, nodeset: xpath, &block)
        end
      end
    end

    # Sometimes we need a second, inner group tag. There are two possible reasons:
    #
    # 1. It's a repeat group, in which case the item label goes inside the inner group.
    # 2. It's a one_screen group, in which case we need to set appearance="field-list"
    #
    # Note both can be true at once.
    def inner_group_tag(&block)
      do_inner_tag = one_screen_appropriate? || repeatable?
      appearance = one_screen_appropriate? ? "field-list" : nil
      conditional_tag(:group, do_inner_tag, appearance: appearance, &block)
    end

    def group_item_name_tag
      # Group item name should only be present for repeatable qing groups.
      return unless respond_to?(:group_item_name) && group_item_name && !group_item_name.empty?
      tag(:label, ref: "jr:itext('#{odk_code}:itemname')")
    end

    def group_hint_tag(xpath)
      return if no_hint?
      content_tag(:input, ref: "#{xpath}/header") do
        tag(:hint, ref: "jr:itext('#{odk_code}:hint')")
      end
    end

    def main_body_tags(xpath)
      # If this is a multilevel fragment, we are supposed to render just one of the subqings. %>
      if multilevel_fragment?
        renderable_children[0].body_tags(group: self, xpath_prefix: xpath)
      else
        safe_str << grid_label_row(xpath_prefix: xpath) << children_body_tags(xpath)
      end
    end

    def children_body_tags(xpath)
      renderable_children.map do |child|
        child.body_tags(group: self, render_mode: render_as_grid? ? :grid : :normal, xpath_prefix: xpath)
      end.reduce(:<<)
    end

    # If any children have grid mode, then the first child is rendered twice:
    # once as a label row and once as a normal row.
    def grid_label_row(xpath_prefix:)
      return +"" unless render_as_grid?
      renderable_children[0].body_tags(group: self, render_mode: :label_row, xpath_prefix: xpath_prefix)
    end
  end
end
