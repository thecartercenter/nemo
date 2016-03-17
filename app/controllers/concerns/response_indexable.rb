# Methods used by controllers that show index lists of Responses.
module ResponseIndexable
  extend ActiveSupport::Concern

  def decorate_responses
    @responses = ResponsesDecorator.decorate(@responses, context: {
      answer_finder: AnswerFinder.new(@responses)
    })
  end
end
