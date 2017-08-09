module Odk
  class FormItemDecorator < ::ApplicationDecorator
    delegate_all

    def odk_code
      return "/data" if object.is_root?
    end

    def absolute_xpath
      decorated_form_items(self_and_ancestors).map(&:odk_code).join("/")
    end

    protected

    def decorated_form_items(form_items)
      form_items.map { |form_item| Odk::DecoratorFactory.decorate(form_item) }
    end
  end
end
