class BroadcastRecipientSerializer < ActiveModel::Serializer
  attributes :id, :text

  def id
    object.prefixed_id
  end

  def text
    object.full_name
  end
end
