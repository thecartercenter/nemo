class UserGroupSerializer < ActiveModel::Serializer
  attributes :id, :name, :klass

  def id
    serialization_options[:include_klass] ? "#{klass}_#{object.id}" : object.id
  end

  def filter(keys)
    keys -= [:klass] unless serialization_options[:include_klass]
    keys
  end

  def klass
    "user_group"
  end
end
