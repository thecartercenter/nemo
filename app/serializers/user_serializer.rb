class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :text

  def filter(keys)
    keys -= [:text] unless serialization_options[:select2]
    keys -= [:name] if serialization_options[:select2]
    keys
  end

  def text
    object.name
  end
end
