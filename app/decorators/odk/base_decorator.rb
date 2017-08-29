module Odk
  class BaseDecorator < ::ApplicationDecorator
    delegate_all

    protected

    def decorate(obj)
      Odk::DecoratorFactory.decorate(obj)
    end

    def decorate_collection(objs)
      Odk::DecoratorFactory.decorate_collection(objs)
    end
  end
end
