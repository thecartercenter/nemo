# frozen_string_literal: true

module Results
  class AnswerGroupDecorator < ResponseNodeDecorator
    def hint
      group_hint
    end

    def classes
      list = []
      list << (root? ? "root-group" : "answer-group")
      list << "repeat-item" if repeatable?
      list.join(" ")
    end
  end
end
