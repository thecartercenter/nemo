# frozen_string_literal: true

module Results
  # Builds a response tree from a form object
  class ResponseTreeBuilder
    def initialize(form)
      @form = form
    end

    def build
      @rn = AnswerGroup.new
      add_children
      @rn
    end

    def add_children
      @form.sorted_children.each do |q|
        @rn.children << Answer.new(questioning_id: q.id, new_rank: q.rank)
      end
    end
  end
end
