# frozen_string_literal: true

module Results
  class AnswerGroupDecorator < ResponseNodeDecorator
    def hint
      group_hint
    end
  end
end
