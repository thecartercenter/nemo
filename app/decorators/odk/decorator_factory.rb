# Makes decorators for various base model types.
module Odk
  class DecoratorFactory
    include Singleton

    def self.decorate(obj)
      instance.decorate(obj)
    end

    def decorate(obj)
      case obj.class.name
      when "QingGroup"
        Odk::QingGroupDecorator.decorate(obj)
      else
        obj
      end
    end
  end
end
