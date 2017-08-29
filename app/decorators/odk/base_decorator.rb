module Odk
  class BaseDecorator < ::ApplicationDecorator
    delegate_all

    protected

    def decorate(items)
      if items.is_a?(Array)
        items.map { |item| Odk::DecoratorFactory.decorate(item) }
      else
        Odk::DecoratorFactory.decorate(items)
      end
    end
  end
end
