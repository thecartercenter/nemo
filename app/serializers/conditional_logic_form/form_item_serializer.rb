# frozen_string_literal: true

module ConditionalLogicForm
  # Serializes Questioning or QingGroup for creating display and skip rule form fields in browser
  class FormItemSerializer < ApplicationSerializer
    fields :id, :display_if, :code, :rank, :full_dotted_rank, :form_id

    field :type do |object|
      object.type.underscore
    end

    association :display_conditions, blueprint: ConditionSerializer
    association :skip_rules, blueprint: SkipRuleSerializer
    association :constraints, blueprint: ConstraintSerializer
    association :refable_qings, blueprint: TargetQuestioningSerializer
    association :later_items, blueprint: TargetFormItemSerializer
  end
end
