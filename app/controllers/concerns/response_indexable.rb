# frozen_string_literal: true

# Methods used by controllers that show index lists of Responses.
module ResponseIndexable
  extend ActiveSupport::Concern

  included do
    helper_method :responses
  end

  def responses
    @decorated_responses ||= # rubocop:disable Naming/MemoizedInstanceVariableName
      PaginatingDecorator.decorate(@responses, context: {answer_finder: AnswerFinder.new(@responses)})
  end
end
