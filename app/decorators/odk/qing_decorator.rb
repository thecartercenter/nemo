module Odk
  class QingDecorator < FormItemDecorator
    delegate_all

    def odk_code
      @odk_code = super
      @odk_code ||= "q#{object.question.id}"
    end

    def xpath_to(other_qing)
      other_qing = decorate(other_qing)
      return other_qing.absolute_xpath if other_qing.top_level?

      # get the paths to the common ancestor
      common_ancestor = object.lowest_common_ancestor(other_qing)

      # include ancestor to get the right number of relative jumps
      ancestor_to_self = object.path_from_ancestor(common_ancestor, include_ancestor: true)

      # include self for easier relative path manipulation
      ancestor_to_other = decorate(other_qing.path_from_ancestor(common_ancestor))

      if ancestor_to_other.size > 0
        args = [other_qing.absolute_xpath]
        unless common_ancestor.root?
          root_to_ancestor = decorate(common_ancestor.path_from_ancestor(ancestors.first, include_self: true))
          root_to_ancestor.each_with_index do |node, i|
            xpath_self_to_cur_group = ([".."] * (ancestry_depth - i - 1)).join("/")
            args << node.absolute_xpath << "position(#{xpath_self_to_cur_group})"
          end
        end

        ancestor_to_other.each do |node|
          args << node.absolute_xpath << "1"
        end

        "indexed-repeat(#{args.join(',')})"
      else
        # use ../ to get to the common ancestor
        xpath_self_to_ancestor = ancestor_to_self.map{ ".." }.join("/")

        # use odk_codes to get to the other qing
        ancestor_to_other += [other_qing]
        xpath_ancestor_to_other = ancestor_to_other.map(&:odk_code).join("/")

        [xpath_self_to_ancestor, xpath_ancestor_to_other].join("/")
      end
    end

    def can_prefill?
      prefill_pattern.present? && qtype.prefillable?
    end
  end
end
