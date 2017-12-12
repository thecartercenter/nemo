class RefableQuestioningSerializer < ActiveModel::Serializer
  attributes :id, :code, :rank, :full_dotted_rank
end
