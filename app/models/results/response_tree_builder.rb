# frozen_string_literal: true

module Results
  # Builds a response tree from a form object
  class ResponseTreeBuilder
    def initialize(form)
      @form = form
    end

    def build
      @rn = AnswerGroup.new
      add_children(@form.root_group.children, @rn)
      @rn
    end

    def add_children(form_node, response_node)
      form_node.each do |q|
        if q.class == QingGroup
          response_node.children << AnswerGroup.new(questioning_id: q.id, new_rank: q.rank)
          add_children(q.children, response_node.children.last) if q.children.present?
        elsif q.multilevel?
          add_multilevel(q, response_node)
        else
          response_node.children << Answer.new(questioning_id: q.id, new_rank: q.rank)
        end
      end
    end

    def add_multilevel(questioning, response_node)
      response_node.children << AnswerSet.new(questioning_id: questioning.id, new_rank: questioning.rank)
      questioning.levels.each_with_index do |_level, index|
        response_node.children.last.children << Answer.new(
          questioning_id: questioning.id,
          new_rank: index
        )
      end
    end
  end
end
