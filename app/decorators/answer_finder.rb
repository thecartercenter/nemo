# frozen_string_literal: true

# Looks up answers for individual questions for a given set of responses.
# Does so in an efficient manner.
class AnswerFinder
  attr_accessor :responses

  def initialize(responses)
    self.responses = responses
  end

  def find(response, question)
    answers_for_question(question)[response.id]
  end

  private

  # Looks up and stores all answers for the given question for the response set.
  # Looks up only 'first' answers where questions have multiple answers
  # (due to multilevel questions or repeat groups)
  def answers_for_question(question)
    @answers_for_question ||= {}
    @answers_for_question[question] ||= Answer
      .joins(:form_item)
      .where(response_id: responses.map(&:id))
      .where("form_items.question_id" => question.id)
      .where("inst_num = 1")
      .where("answers.rank = 1")
      .index_by(&:response_id)
  end
end
