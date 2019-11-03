# frozen_string_literal: true

class API::V1::AnswerSerializer < ActiveModel::Serializer
  attributes :id, :code, :question, :value
  format_keys :underscore

  def filter(keys)
    keys -= (scope.params[:controller] == "api/v1/answers" ? [:code, :question] : [])
  end

  def code
    object.question.code
  end

  def question
    object.question.name
  end

  def value
    if %w[image audio video document].include?(object.qtype_name)
      if object.media_object.present?
        locale = configatron.key?(:preferred_locales) ? configatron.preferred_locales.first.to_s : "en"
        media_object_path(id: object.media_object.id,
                          locale: locale,
                          mission_name: scope.params[:mission_name],
                          type: object.qtype_name.pluralize)
      end
    else
      object.casted_value
    end
  end
end
