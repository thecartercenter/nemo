# frozen_string_literal: true

# Makes decorators for various base model types.
module ODK
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
        when "Form" then ODK::FormDecorator
        when "QingGroup" then ODK::QingGroupDecorator
        when "ODK::QingGroupFragment" then ODK::QingGroupDecorator
        when "Question" then ODK::QuestionDecorator
        when "OptionSet" then ODK::OptionSetDecorator
        when "Questioning" then ODK::QingDecorator
        when "Condition" then ODK::ConditionDecorator
        when "Subqing" then ODK::SubqingDecorator
        when "Forms::ConditionGroup" then ODK::ConditionGroupDecorator
        end
      klass.nil? ? obj : klass.new(obj, context: context)
    end
  end
end
