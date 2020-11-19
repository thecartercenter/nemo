# frozen_string_literal: true

require "will_paginate/array"
class API::V1::AnswersController < API::V1::BaseController
  def index
    find_form

    unless performed?
      if params[:question_id].blank?
        return render(json: {errors: ["question_id_required"]}, status: :unprocessable_entity)
      elsif @form.questions.map(&:id).exclude?(params[:question_id])
        return render(json: {errors: ["question_not_found"]}, status: :unprocessable_entity)
      end

      question = Question.find(params[:question_id])

      if question.access_level == "private"
        return render(json: {errors: ["access_denied"]}, status: :forbidden)
      end

      if question.multimedia?
        return render(json: {errors: ["question_type_not_api_accessible"]}, status: :unprocessable_entity)
      end

      answers = Answer.includes(:response, :form_item).where(responses: {form_id: params[:form_id]})
        .where(form_items: {question_id: params[:question_id]}).newest_first

      answers = add_date_filter(answers)

      paginate(json: API::V1::AnswerSerializer.render_as_json(answers, view: :api))
    end
  end
end
