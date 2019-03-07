# frozen_string_literal: true

class ResponseDecorator < ApplicationDecorator
  delegate_all

  def shortcode
    model.shortcode&.upcase
  end

  # Gets the answer to the given question on the response.
  def answer_for(question)
    context[:answer_finder].find(self, question)
  end

  # Returns the edit path if the user has edit abilities, else the show path.
  def default_path
    @default_path ||= h.response_path(object)
  end
end
