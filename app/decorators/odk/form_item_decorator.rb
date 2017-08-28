module Odk
  class FormItemDecorator < ::ApplicationDecorator
    delegate_all

    def odk_code
      return "/data" if object.is_root?
    end

    def absolute_xpath
      decorate(self_and_ancestors).map(&:odk_code).join("/")
    end

    protected

    def decorate(form_items)
      if form_items.is_a?(Array)
        form_items.map { |form_item| Odk::DecoratorFactory.decorate(form_item) }
      else
        Odk::DecoratorFactory.decorate(form_items)
      end
    end
  end
end
