module Odk
  class FormItemDecorator < BaseDecorator
    delegate_all

    def odk_code
      return "/data" if object.is_root?
    end

    def absolute_xpath
      decorate_collection(self_and_ancestors).map(&:odk_code).join("/")
    end
  end
end
