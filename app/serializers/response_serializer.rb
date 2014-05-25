class ResponseSerializer < ActiveModel::Serializer
  attributes :id, :submitter, :created_at, :updated_at

  has_many :answers, serializer: QuestionSerializer

  def submitter
    object.user_id
  end
 
  def answers
    object.answers.public_access
  end

end
