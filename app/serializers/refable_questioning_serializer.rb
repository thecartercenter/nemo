class RefableQuestioningSerializer < ActiveModel::Serializer
  attributes :id, :display_if, :code, :rank, :full_dotted_rank
end
