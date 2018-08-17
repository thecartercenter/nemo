# frozen_string_literal: true

module Results
  class AnswerSetDecorator < ResponseNodeDecorator
    def classes
      "answer-set form-field qtype-select-one #{mode_class}"
    end
  end
end
