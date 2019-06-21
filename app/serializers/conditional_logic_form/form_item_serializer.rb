# frozen_string_literal: true

module ConditionalLogicForm
  # Serializes Questioning or QingGroup for creating display and skip rule form fields in browser
  class FormItemSerializer < ApplicationSerializer
    attributes :id, :display_if, :code, :rank, :full_dotted_rank, :form_id, :type

    has_many :display_conditions, serializer: ConditionSerializer
    has_many :skip_rules, serializer: SkipRuleSerializer
    has_many :constraints, serializer: ConstraintSerializer
    has_many :refable_qings, serializer: TargetQuestioningSerializer
    has_many :later_items, serializer: TargetFormItemSerializer

    def type
      object.type.underscore
    end
  end
end
