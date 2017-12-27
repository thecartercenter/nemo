# Makes decorators for various base model types.
module Odk
  class DecoratorFactory
    include Singleton

    def self.decorate(obj)
      instance.decorate(obj)
    end

    def self.decorate_collection(objs)
      objs.map { |obj| instance.decorate(obj) }
    end

    def decorate(obj)
      if obj.respond_to?(:decorated?) # used in testing
        return   obj
      end

      case obj.class.name
      when "Form"
        FormDecorator.decorate(obj)
      when "QingGroup"
        QingGroupDecorator.decorate(obj)
      when "Questioning"
        QingDecorator.decorate(obj)
      when "Condition"
        ConditionDecorator.decorate(obj)
      when "Subqing"
        SubqingDecorator.decorate(obj)
      when "Forms::ConditionGroup"
        ConditionGroupDecorator.decorate(obj)
      else
        obj
      end
    end
  end
end
