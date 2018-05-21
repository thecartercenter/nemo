# frozen_string_literal: true

module Results
  # Builds a response tree from a form object
  class ResponseTreeBuilder
    def initialize(form)
      @form = form
    end

    def build
      @rn = AnswerGroup.new
      add_children(@form.root_group, @rn)
      @rn
    end

    def add_children(form_node, response_node)
      form_node.children.each do |q|
        if q.class == QingGroup
          response_node.children << AnswerGroup.new(questioning_id: q.id, new_rank: q.rank)
          add_children(q, response_node.children.last) if q.children.present?
        else
          response_node.children << Answer.new(questioning_id: q.id, new_rank: q.rank)
        end
      end
    end
  end
end
