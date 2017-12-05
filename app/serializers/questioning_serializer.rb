class QuestioningSerializer < ActiveModel::Serializer
  attributes :id, :display_if

  has_many :display_conditions, serializer: ConditionViewSerializer
end
