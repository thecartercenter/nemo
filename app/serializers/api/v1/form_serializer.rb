# learn more: http://railscasts.com/episodes/409-active-model-serializers
class API::V1::FormSerializer < ActiveModel::Serializer
  attributes :id, :name, :responses_count, :created_at, :updated_at, :access_level

  def access_level
    I18n.t("api_levels.level_#{object.access_level}")
  end
end
