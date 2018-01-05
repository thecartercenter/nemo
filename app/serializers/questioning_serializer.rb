class QuestioningSerializer < ActiveModel::Serializer
  attributes :id, :display_if, :code, :rank, :full_dotted_rank

  has_many :display_conditions, serializer: ConditionViewSerializer
  has_many :skip_rules, serializer: SkipRuleSerializer
  has_many :refable_qings, serializer: RefableQuestioningSerializer
end
