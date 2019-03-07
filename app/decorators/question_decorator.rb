# frozen_string_literal: true

class QuestionDecorator < ApplicationDecorator
  delegate_all

  def self.collection_decorator_class
    PaginatingDecorator
  end

  # Returns the edit path if the user has edit abilities, else the show path.
  def default_path
    @default_path ||= h.can?(:update, object) ? h.edit_question_path(object) : h.question_path(object)
  end
end
