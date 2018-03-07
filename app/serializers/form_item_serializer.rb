# frozen_string_literal: true

# Serializes Questioning or QingGroup for creating display and skip rule form fields in browser
class FormItemSerializer < ActiveModel::Serializer
  attributes :id, :display_if, :code, :rank, :full_dotted_rank, :form_id, :type
  format_keys :lower_camel

  has_many :display_conditions, serializer: ConditionViewSerializer
  has_many :skip_rules, serializer: SkipRuleSerializer
  has_many :refable_qings, serializer: TargetFormItemSerializer
  has_many :later_items, serializer: TargetFormItemSerializer

  def type
    object.type.underscore
  end
end
