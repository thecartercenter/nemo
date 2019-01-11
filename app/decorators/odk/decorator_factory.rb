# Makes decorators for various base model types.
module Odk
  class DecoratorFactory
    include Singleton

    def self.decorate(obj, context: {})
      instance.decorate(obj, context: context)
    end

    def self.decorate_collection(objs, context: {})
      objs.map { |obj| instance.decorate(obj, context: context) }
    end

    def decorate(obj, context: {})
      klass =
        case obj.class.name
        when "Form" then Odk::FormDecorator
        when "QingGroup" then Odk::QingGroupDecorator
        when "Question" then Odk::QuestionDecorator
        when "OptionSet" then Odk::OptionSetDecorator
        when "Questioning" then Odk::QingDecorator
        when "Condition" then Odk::ConditionDecorator
        when "Subqing" then Odk::SubqingDecorator
        when "Forms::ConditionGroup" then Odk::ConditionGroupDecorator
        end
      klass.nil? ? obj : klass.new(obj, context: context)
    end
  end
end
