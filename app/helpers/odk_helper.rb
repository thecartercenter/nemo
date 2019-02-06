# frozen_string_literal: true

module OdkHelper
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
  def odk_group_or_fragment(node, xpath_prefix)
    # No need to render empty groups/fragments
    return "" if node.is_childless?

    xpath = "#{xpath_prefix}/#{node.odk_code}"
    odk_group_or_fragment_wrapper(node, xpath) do
      fragments = Odk::QingGroupPartitioner.new.fragment(node)
      if fragments
        fragments.map { |f| odk_group_or_fragment(f, xpath_prefix) }.reduce(:<<)
      else
        odk_inner_group_tag(node) do
          # We include the hint here.
          # In the case of fragments, this means we include hint each time, which is correct.
          # This covers the case where `node` is a fragment, because fragments should always
          # be shown on one screen since that's what they're for.
          odk_group_item_name(node, xpath) << odk_group_hint(node, xpath) << odk_group_body(node, xpath)
        end
      end
    end
  end

  def odk_group_or_fragment_wrapper(node, xpath, &block)
    if node.fragment?
      # Fragments need no outer wrapper, they will get wrapped by field-list further in.
      capture(&block)
    else
      # Groups should get wrapped in a group tag and include the label.
      # Also a repeat tag if the group is repeatable
      content_tag(:group, ref: xpath) do
        tag(:label, ref: "jr:itext('#{node.odk_code}:label')") <<
          conditional_tag(:repeat, node.repeatable?, nodeset: xpath) do
            capture(&block)
          end
      end
    end
  end

  # Sometimes we need a second, inner group tag. There are two possible reasons:
  #
  # 1. It's a repeat group, in which case the item label goes inside the inner group.
  # 2. It's a one_screen group, in which case we need to set appearance="field-list"
  #
  # Note both can be true at once.
  def odk_inner_group_tag(node, &block)
    do_inner_tag = node.one_screen_appropriate? || node.repeatable?
    appearance = node.one_screen_appropriate? ? "field-list" : nil
    conditional_tag(:group, do_inner_tag, appearance: appearance) do
      capture(&block)
    end
  end

  def odk_group_hint(node, xpath)
    if node.no_hint?
      "".html_safe
    else
      content_tag(:input, ref: "#{xpath}/header") do
        tag(:hint, ref: "jr:itext('#{node.odk_code}:hint')")
      end
    end
  end

  def odk_group_item_name(node, _xpath)
    # Group item name should only be present for repeatable qing groups.
    if node.respond_to?(:group_item_name) && node.group_item_name && !node.group_item_name.empty?
      tag(:label, ref: "jr:itext('#{node.odk_code}:itemname')")
    else
      "".html_safe
    end
  end

  def odk_group_body(node, xpath)
    render("forms/odk/group_body", node: Odk::DecoratorFactory.decorate(node), xpath: xpath)
  end
end
