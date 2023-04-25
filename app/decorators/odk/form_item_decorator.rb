# frozen_string_literal: true

module ODK
  class FormItemDecorator < BaseDecorator
    delegate_all

    def odk_code
      CodeMapper.instance.code_for_item(object)
    end

    def absolute_xpath
      decorate_collection(self_and_ancestors).map(&:odk_code).join("/")
    end

    def xpath_to(dest, prepend_current: false)
      dest = decorate(dest)
      return "current()" if object == dest.object && prepend_current
      return "." if object == dest.object
      return dest.absolute_xpath if dest.top_level?
      return dest.absolute_xpath if object.type == "QingGroup" && object.repeat_count?

      current_prefix = prepend_current ? +"current()/" : +""

      common_ancestor = object.lowest_common_ancestor(dest)
      ancestor_to_self = object.path_from_ancestor(common_ancestor, include_ancestor: true)
      ancestor_to_dest = decorate_collection(dest.path_from_ancestor(common_ancestor))

      if !ancestor_to_dest.empty?
        args = [dest.absolute_xpath]
        unless common_ancestor.root?
          root_to_ancestor = common_ancestor.path_from_ancestor(ancestors.first, include_self: true)
          root_to_ancestor = decorate_collection(root_to_ancestor)
          root_to_ancestor.each_with_index do |node, i|
            xpath_self_to_cur_group = ([".."] * (ancestry_depth - i - 1)).join("/")
            args << node.absolute_xpath << "position(#{current_prefix}#{xpath_self_to_cur_group})"
          end
        end

        ancestor_to_dest.each do |node|
          args << node.absolute_xpath << "1"
        end

        "indexed-repeat(#{args.join(',')})"
      else
        # use ../ to get to the common ancestor
        xpath_self_to_ancestor = ancestor_to_self.map { ".." }.join("/")

        # use odk_codes to get to the other qing
        ancestor_to_dest += [dest]
        xpath_ancestor_to_dest = ancestor_to_dest.map(&:odk_code).join("/")

        current_prefix << [xpath_self_to_ancestor, xpath_ancestor_to_dest].join("/")
      end
    end

    # Boolean XPath expression determining whether to show this item.
    def relevance
      computed_condition_group = context[:condition_computer].condition_group_for(object)
      ConditionGroupDecorator.decorate(computed_condition_group).to_odk
    end

    def display_conditions
      @display_conditions ||= decorate_collection(object.display_conditions)
    end

    def grid_renderable?(option_set:)
      is_a?(Questioning) && qtype.select_one? && !multilevel? && option_set == object.option_set
    end
  end
end
