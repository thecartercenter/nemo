module Odk
  class QingDecorator < FormItemDecorator
    delegate_all

    def odk_code
      @odk_code = super
      @odk_code ||= "q#{object.question.id}"
    end

    def relative_xpath(other_qing)
      # get the paths to the common ancestor
      common_ancestor = object.lowest_common_ancestor(other_qing)

      ancestor_path = object.path_to_ancestor(common_ancestor)
      other_ancestor_path = other_qing.path_to_ancestor(common_ancestor)
      decorated_path_to_other = decorated_form_items(other_ancestor_path)

      # use ../ to get to the common ancestor
      xpath_self_to_ancestor = ancestor_path.map{ ".." }.join("/")

      # use odk_codes to get to the other qing
      xpath_ancestor_to_other = decorated_path_to_other.map(&:odk_code).join("/")

      [xpath_self_to_ancestor, xpath_ancestor_to_other].join("/")
    end
  end
end
