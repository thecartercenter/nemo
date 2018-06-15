# frozen_string_literal: true

class ResponseDecorator < ApplicationDecorator
  delegate_all

  def shortcode
    model.shortcode.try(:upcase)
  end

  # Gets the answer to the given question on the response.
  def answer_for(question)
    context[:answer_finder].find(self, question)
  end
end
