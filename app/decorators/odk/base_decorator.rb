module Odk
  class BaseDecorator < ::ApplicationDecorator
    delegate_all

    protected

    def decorate(obj)
      DecoratorFactory.decorate(obj)
    end

    def decorate_collection(objs)
      DecoratorFactory.decorate_collection(objs)
    end
  end
end
