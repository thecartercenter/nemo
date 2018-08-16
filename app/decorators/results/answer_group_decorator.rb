# frozen_string_literal: true

module Results
  class AnswerGroupDecorator < ApplicationDecorator
    delegate_all

    def hint
      group_hint
    end
  end
end
